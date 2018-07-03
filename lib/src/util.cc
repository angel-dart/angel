#include <dart_api.h>
#include "wings.h"

void wings_AddressToString(Dart_NativeArguments arguments) {
    char *address;
    void *data;
    intptr_t length;
    bool ipv6;
    Dart_TypedData_Type type;

    Dart_Handle address_handle = Dart_GetNativeArgument(arguments, 0);
    Dart_Handle ipv6_handle = Dart_GetNativeArgument(arguments, 1);
    HandleError(Dart_BooleanValue(ipv6_handle, &ipv6));
    sa_family_t family;

    if (ipv6) {
        family = AF_INET6;
        address = (char *) Dart_ScopeAllocate(INET6_ADDRSTRLEN);
    } else {
        family = AF_INET;
        address = (char *) Dart_ScopeAllocate(INET_ADDRSTRLEN);
    }

    HandleError(Dart_TypedDataAcquireData(address_handle, &type, &data, &length));
    auto *ptr = inet_ntop(family, data, address, INET_ADDRSTRLEN);
    HandleError(Dart_TypedDataReleaseData(address_handle));

    if (ptr == nullptr) {
        if (ipv6)
            Dart_ThrowException(Dart_NewStringFromCString("Invalid IPV6 address."));
        else
            Dart_ThrowException(Dart_NewStringFromCString("Invalid IPV4 address."));
    } else {
        Dart_SetReturnValue(arguments, Dart_NewStringFromCString(address));
    }
}