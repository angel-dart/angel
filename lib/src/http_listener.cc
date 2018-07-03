#include <dart_native_api.h>
#include <thread>
#include "wings.h"
#include "wings_thread.h"

void handleMessage(Dart_Port destPortId, Dart_CObject *message);

void wings_StartHttpListener(Dart_NativeArguments arguments)
{
    Dart_Port port = Dart_NewNativePort("angel_wings", handleMessage, true);
    Dart_SetReturnValue(arguments, Dart_NewSendPort(port));
}

int64_t get_int(Dart_CObject *obj)
{
    if (obj == nullptr)
        return 0;
    switch (obj->type)
    {
    case Dart_CObject_kInt32:
        return (int64_t)obj->value.as_int32;
    case Dart_CObject_kInt64:
        return obj->value.as_int64;
    default:
        return 0;
    }
}

void handleMessage(Dart_Port destPortId, Dart_CObject *message)
{
    // We always expect an array to be sent.
    Dart_CObject_Type firstType = message->value.as_array.values[0]->type;

    // If it's a SendPort, then start a new thread that listens for incoming connections.
    if (firstType == Dart_CObject_kSendPort)
    {
        std::lock_guard<std::mutex> lock(serverInfoVectorMutex);
        auto *threadInfo = new wings_thread_info;
        threadInfo->port = message->value.as_array.values[0]->value.as_send_port.id;
        threadInfo->serverInfo = serverInfoVector.at((unsigned long)get_int(message->value.as_array.values[1]));
        std::thread workerThread(wingsThreadMain, threadInfo);
        workerThread.detach();
    }
    else if (firstType == Dart_CObject_kBool)
    {
        // The Dart world is trying to close this port.
        Dart_Port port = message->value.as_array.values[1]->value.as_send_port.id;
        Dart_CloseNativePort(port);
    }
}