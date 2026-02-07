#pragma once

#include <string>
#include <windows.h>
#include <thread>
#include <atomic>
#include <functional>

// Custom message for process termination
#define WM_PROCESS_TERMINATED (WM_APP + 1)

class ProcessManager {
public:
    ProcessManager();
    ~ProcessManager();

    void SetMainWindowHandle(HWND hwnd);
    void SetLogCallback(std::function<void(const std::string&)> callback);
    bool Start(const std::string& config_content, bool hide_console);
    void Stop();
    bool IsRunning();

private:
    void MonitorProcess();
    void ReadFromPipe(HANDLE pipe);

    HANDLE hProcess_ = NULL;
    HANDLE hJobObject_ = NULL;
    std::atomic<bool> is_running_ = false;
    
    std::thread monitor_thread_;
    HANDLE stop_event_ = NULL;
    HWND main_window_handle_ = nullptr;

    std::function<void(const std::string&)> log_callback_;
    HANDLE hStdOutRead_ = NULL;
    std::thread stdout_thread_;
};
