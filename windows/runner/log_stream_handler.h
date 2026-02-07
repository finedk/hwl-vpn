#pragma once

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler.h>
#include <flutter/standard_method_codec.h>

class LogStreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
public:
    LogStreamHandler();
    ~LogStreamHandler() override;

    void SendLog(const std::string& log);

protected:
    std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
        const flutter::EncodableValue* arguments,
        std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) override;

    std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
        const flutter::EncodableValue* arguments) override;

private:
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};
