#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>

#include "flutter_window.h"

#include <optional>
#include <fstream>
#include <string>
#include <vector>
#include <memory>

#include "flutter/generated_plugin_registrant.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

namespace {
  std::string GetLocalIpAddress() {
    std::string hotspot_ip = "";
    std::string gateway_ip = "";

    ULONG buffer_size = 15000;
    std::unique_ptr<char[]> buffer(new char[buffer_size]);
    PIP_ADAPTER_ADDRESSES p_adapters = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.get());

    DWORD flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER | GAA_FLAG_INCLUDE_GATEWAYS;
    DWORD result = GetAdaptersAddresses(AF_INET, flags, NULL, p_adapters, &buffer_size);

    if (result == ERROR_BUFFER_OVERFLOW) {
        buffer.reset(new char[buffer_size]);
        p_adapters = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.get());
        result = GetAdaptersAddresses(AF_INET, flags, NULL, p_adapters, &buffer_size);
    }

    if (result != NO_ERROR) {
        return "";
    }

    for (PIP_ADAPTER_ADDRESSES p_curr_adapter = p_adapters; p_curr_adapter != NULL; p_curr_adapter = p_curr_adapter->Next) {
        if (p_curr_adapter->OperStatus != IfOperStatusUp) {
            continue;
        }

        if (wcsstr(p_curr_adapter->Description, L"Microsoft Wi-Fi Direct Virtual Adapter") != nullptr) {
            for (IP_ADAPTER_UNICAST_ADDRESS* p_unicast = p_curr_adapter->FirstUnicastAddress; p_unicast != NULL; p_unicast = p_unicast->Next) {
                if (p_unicast->Address.lpSockaddr->sa_family == AF_INET) {
                    char ip_str[INET_ADDRSTRLEN];
                    sockaddr_in* sai = reinterpret_cast<sockaddr_in*>(p_unicast->Address.lpSockaddr);
                    if (inet_ntop(AF_INET, &(sai->sin_addr), ip_str, INET_ADDRSTRLEN) != NULL) {
                        hotspot_ip = ip_str;
                        break;
                    }
                }
            }
        }
        else if (p_curr_adapter->IfType != IF_TYPE_TUNNEL && p_curr_adapter->FirstGatewayAddress != NULL) {
             for (IP_ADAPTER_UNICAST_ADDRESS* p_unicast = p_curr_adapter->FirstUnicastAddress; p_unicast != NULL; p_unicast = p_unicast->Next) {
                if (p_unicast->Address.lpSockaddr->sa_family == AF_INET) {
                     char ip_str[INET_ADDRSTRLEN];
                    sockaddr_in* sai = reinterpret_cast<sockaddr_in*>(p_unicast->Address.lpSockaddr);
                    if (inet_ntop(AF_INET, &(sai->sin_addr), ip_str, INET_ADDRSTRLEN) != NULL) {
                        if (gateway_ip.empty()) {
                           gateway_ip = ip_str;
                        }
                    }
                }
            }
        }
    }

    if (!hotspot_ip.empty()) {
        return hotspot_ip;
    }
    if (!gateway_ip.empty()) {
        return gateway_ip;
    }

    for (PIP_ADAPTER_ADDRESSES p_curr_adapter = p_adapters; p_curr_adapter != NULL; p_curr_adapter = p_curr_adapter->Next) {
        if (p_curr_adapter->OperStatus == IfOperStatusUp && 
            (p_curr_adapter->IfType == IF_TYPE_ETHERNET_CSMACD || p_curr_adapter->IfType == IF_TYPE_IEEE80211)) {
            
            if (wcsstr(p_curr_adapter->Description, L"VMware") != nullptr ||
                wcsstr(p_curr_adapter->Description, L"VirtualBox") != nullptr ||
                wcsstr(p_curr_adapter->FriendlyName, L"vEthernet (WSL)") != nullptr) {
                continue;
            }

            for (IP_ADAPTER_UNICAST_ADDRESS* p_unicast = p_curr_adapter->FirstUnicastAddress; p_unicast != NULL; p_unicast = p_unicast->Next) {
                if (p_unicast->Address.lpSockaddr->sa_family == AF_INET) {
                    char ip_str[INET_ADDRSTRLEN];
                    sockaddr_in* sai = reinterpret_cast<sockaddr_in*>(p_unicast->Address.lpSockaddr);
                    if (inet_ntop(AF_INET, &(sai->sin_addr), ip_str, INET_ADDRSTRLEN) != NULL) {
                        return std::string(ip_str);
                    }
                }
            }
        }
    }

    return "";
  }
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  process_manager_.SetMainWindowHandle(GetHandle());

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Set up method channel.
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.hwl_vpn.app/channel",
      &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("startService") == 0) {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (!args) {
            result->Error("ARG_ERROR", "Invalid arguments");
            return;
          }
          auto config_json_it = args->find(flutter::EncodableValue("config"));
          if (config_json_it == args->end()) {
            result->Error("ARG_ERROR", "Missing 'config' argument.");
            return;
          }
          const std::string config_json = std::get<std::string>(config_json_it->second);

          auto hide_console_it = args->find(flutter::EncodableValue("hideSingboxConsole"));
          bool hide_console = true; // Default to hiding
          if (hide_console_it != args->end()) {
              if (const auto* value = std::get_if<bool>(&hide_console_it->second)) {
                  hide_console = *value;
              }
          }

          bool success = this->process_manager_.Start(config_json, hide_console);
          
          if (success) {
            result->Success();
            channel_->InvokeMethod("updateStatus", std::make_unique<flutter::EncodableValue>("Started"));
          } else {
            result->Error("START_FAILED", "Failed to start sing-box.exe process.");
            channel_->InvokeMethod("updateStatus", std::make_unique<flutter::EncodableValue>("Error starting process"));
          }
        } else if (call.method_name().compare("stopService") == 0) {
          this->process_manager_.Stop();
          result->Success();
          channel_->InvokeMethod("updateStatus", std::make_unique<flutter::EncodableValue>("Stopped"));
        } else if (call.method_name().compare("getIpAddress") == 0) {
          std::string ip = GetLocalIpAddress();
          if (!ip.empty()) {
            result->Success(flutter::EncodableValue(ip));
          } else {
            result->Success();
          }
        }
         else {
          result->NotImplemented();
        }
      });
  
  // Set up log event channel
  auto log_stream_handler = std::make_unique<LogStreamHandler>();
  log_handler_ = log_stream_handler.get();
  log_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.hwl.hwl-vpn/logs",
      &flutter::StandardMethodCodec::GetInstance());
  log_channel_->SetStreamHandler(std::move(log_stream_handler));

  process_manager_.SetLogCallback([hwnd = GetHandle()](const std::string& log) {
    char* log_str = new char[log.length() + 1];
    strcpy_s(log_str, log.length() + 1, log.c_str());
    PostMessage(hwnd, WM_LOG_MESSAGE, reinterpret_cast<WPARAM>(log_str), 0);
  });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  process_manager_.Stop();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_PROCESS_TERMINATED:
      channel_->InvokeMethod("onVpnStopped", nullptr);
      return 0;
    case WM_LOG_MESSAGE: {
      char* log_str = reinterpret_cast<char*>(wparam);
      if (log_handler_) {
          log_handler_->SendLog(log_str);
      }
      delete[] log_str;
      return 0;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
