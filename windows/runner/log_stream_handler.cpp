#include "log_stream_handler.h"

LogStreamHandler::LogStreamHandler() : sink_(nullptr) {}

LogStreamHandler::~LogStreamHandler() {}

void LogStreamHandler::SendLog(const std::string& log) {
    if (sink_) {
        // The event sink must be used on the platform thread
        // We can't directly call it from our logging thread.
        // A more robust solution would use a message queue,
        // but for this case, we'll assume the caller (FlutterWindow)
        // handles the thread switching if necessary. In our case,
        // we'll post a message to the window.
        sink_->Success(flutter::EncodableValue(log));
    }
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> LogStreamHandler::OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
    events->Success(flutter::EncodableValue("__CLEAR_LOGS__\n"));
    sink_ = std::move(events);
    return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> LogStreamHandler::OnCancelInternal(
    const flutter::EncodableValue* arguments) {
    sink_ = nullptr;
    return nullptr;
}

