#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "win32_window.h"
#include "process_manager.h"
#include "log_stream_handler.h"

#define WM_LOG_MESSAGE (WM_APP + 2)

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // The process manager for sing-box.
  ProcessManager process_manager_;

  // The method channel for communication with Dart.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  // The event channel for logs.
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> log_channel_;
  LogStreamHandler* log_handler_ = nullptr;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
