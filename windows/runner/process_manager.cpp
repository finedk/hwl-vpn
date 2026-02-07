#include "process_manager.h"
#include <iostream>
#include <shellapi.h>
#include <string>

ProcessManager::ProcessManager() {
    stop_event_ = CreateEvent(NULL, TRUE, FALSE, NULL);
    hJobObject_ = CreateJobObject(NULL, NULL);
    if (hJobObject_ != NULL) {
        JOBOBJECT_EXTENDED_LIMIT_INFORMATION jeli = { 0 };
        jeli.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
        SetInformationJobObject(hJobObject_, JobObjectExtendedLimitInformation, &jeli, sizeof(jeli));
    }
}

ProcessManager::~ProcessManager() {
    Stop();
    if (stop_event_) {
        CloseHandle(stop_event_);
    }
    if (hJobObject_) {
        CloseHandle(hJobObject_);
    }
}

void ProcessManager::SetMainWindowHandle(HWND hwnd) {
    main_window_handle_ = hwnd;
}

void ProcessManager::SetLogCallback(std::function<void(const std::string&)> callback) {
    log_callback_ = callback;
}

void ProcessManager::MonitorProcess() {
    if (hProcess_ == NULL || stop_event_ == NULL) {
        return;
    }

    HANDLE handles[] = {hProcess_, stop_event_};
    DWORD wait_result = WaitForMultipleObjects(2, handles, FALSE, INFINITE);

    if (wait_result == WAIT_OBJECT_0 + 0) {
        if (is_running_.load()) {
            is_running_ = false;
            CloseHandle(hProcess_);
            hProcess_ = NULL;
            if (main_window_handle_) {
                PostMessage(main_window_handle_, WM_PROCESS_TERMINATED, 0, 0);
            }
        }
    }
}

void ProcessManager::ReadFromPipe(HANDLE pipe) {
    char buffer[4096];
    DWORD bytesRead;
    std::string line_buffer;

    while (ReadFile(pipe, buffer, sizeof(buffer) - 1, &bytesRead, NULL) && bytesRead > 0) {
        if (log_callback_) {
            buffer[bytesRead] = '\0';
            line_buffer += buffer;
            size_t EOL_pos;
            while ((EOL_pos = line_buffer.find('\n')) != std::string::npos) {
                std::string line = line_buffer.substr(0, EOL_pos + 1);
                // This is a simple way to add an emoji, assuming logs from sing-box
                // are what we want to decorate.
                log_callback_("📦 " + line);
                line_buffer.erase(0, EOL_pos + 1);
            }
        }
    }
    if (!line_buffer.empty() && log_callback_) {
        log_callback_("📦 " + line_buffer + "\n");
    }
}

bool ProcessManager::Start(const std::string& config_content, bool hide_console) {
    if (IsRunning()) {
        std::cout << "[ProcessManager] Process is already running." << std::endl;
        return true;
    }

    if (log_callback_) log_callback_("🚀 Starting VPN service...\n");

    char exe_path[MAX_PATH];
    GetModuleFileNameA(NULL, exe_path, MAX_PATH);
    std::string::size_type pos = std::string(exe_path).find_last_of("/\\");
    std::string app_dir = std::string(exe_path).substr(0, pos);
    std::string executable_path = app_dir + "\\sing-box.exe";
    
    std::string command = std::string("\"") + executable_path + std::string("\" run -c stdin");
    
    SECURITY_ATTRIBUTES sa;
    sa.nLength = sizeof(SECURITY_ATTRIBUTES);
    sa.bInheritHandle = TRUE;
    sa.lpSecurityDescriptor = NULL;

    HANDLE hStdInRead, hStdInWrite;
    if (!CreatePipe(&hStdInRead, &hStdInWrite, &sa, 0)) {
        if (log_callback_) log_callback_("❌ CreatePipe (stdin) failed.\n");
        return false;
    }
    SetHandleInformation(hStdInWrite, HANDLE_FLAG_INHERIT, 0);

    HANDLE hStdOutRead, hStdOutWrite;
    if (!CreatePipe(&hStdOutRead, &hStdOutWrite, &sa, 0)) {
        if (log_callback_) log_callback_("❌ CreatePipe (stdout) failed.\n");
        CloseHandle(hStdInRead);
        CloseHandle(hStdInWrite);
        return false;
    }
    SetHandleInformation(hStdOutRead, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    si.hStdInput = hStdInRead;
    si.hStdOutput = hStdOutWrite;
    si.hStdError = hStdOutWrite;
    si.dwFlags |= STARTF_USESTDHANDLES;

    ZeroMemory(&pi, sizeof(pi));

    DWORD creation_flags = hide_console ? CREATE_NO_WINDOW : 0;

    if (!CreateProcessA(NULL, &command[0], NULL, NULL, TRUE, creation_flags, NULL, app_dir.c_str(), &si, &pi)) {
        DWORD error = GetLastError();
        if (log_callback_) log_callback_("❌ CreateProcess failed with error: " + std::to_string(error) + "\n");
        CloseHandle(hStdInRead);
        CloseHandle(hStdInWrite);
        CloseHandle(hStdOutRead);
        CloseHandle(hStdOutWrite);
        return false;
    }

    if (hJobObject_ != NULL) {
        if (!AssignProcessToJobObject(hJobObject_, pi.hProcess)) {
            if (log_callback_) log_callback_("❌ AssignProcessToJobObject failed. Error: " + std::to_string(GetLastError()) + "\n");
            TerminateProcess(pi.hProcess, 1);
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            CloseHandle(hStdInRead);
            CloseHandle(hStdInWrite);
            CloseHandle(hStdOutRead);
            CloseHandle(hStdOutWrite);
            return false;
        }
    }

    CloseHandle(hStdInRead);
    CloseHandle(hStdOutWrite);

    DWORD bytesWritten;
    if (!WriteFile(hStdInWrite, config_content.c_str(), static_cast<DWORD>(config_content.length()), &bytesWritten, NULL)) {
        if (log_callback_) log_callback_("❌ WriteFile to pipe failed.\n");
        CloseHandle(hStdInWrite);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        CloseHandle(hStdOutRead);
        return false;
    }

    CloseHandle(hStdInWrite);

    hProcess_ = pi.hProcess;
    hStdOutRead_ = hStdOutRead;
    is_running_ = true;

    if (monitor_thread_.joinable()) monitor_thread_.join();
    ResetEvent(stop_event_);
    monitor_thread_ = std::thread(&ProcessManager::MonitorProcess, this);

    if (stdout_thread_.joinable()) stdout_thread_.join();
    stdout_thread_ = std::thread(&ProcessManager::ReadFromPipe, this, hStdOutRead_);
    
    CloseHandle(pi.hThread);

    if (log_callback_) log_callback_("✅ Process started successfully.\n");
    return true;
}

void ProcessManager::Stop() {
    if (!is_running_.load()) {
        return;
    }
    if (log_callback_) log_callback_("🛑 Stopping VPN service...\n");

    if (stop_event_) SetEvent(stop_event_);
    if (monitor_thread_.joinable()) monitor_thread_.join();
    
    if (hProcess_ != NULL) {
        TerminateProcess(hProcess_, 0);
        CloseHandle(hProcess_);
        hProcess_ = NULL;
    }

    if(hStdOutRead_ != NULL) {
        CloseHandle(hStdOutRead_);
        hStdOutRead_ = NULL;
    }
    
    if (stdout_thread_.joinable()) stdout_thread_.join();

    is_running_ = false;
}

bool ProcessManager::IsRunning() {
    if (!is_running_.load() || hProcess_ == NULL) {
        return false;
    }
    DWORD exit_code;
    if (GetExitCodeProcess(hProcess_, &exit_code)) {
        if (exit_code == STILL_ACTIVE) {
            return true;
        }
    }
    is_running_ = false;
    hProcess_ = NULL;
    return false;
}
