# CVE-2025-25364: Product and Version Information

Product: Speedify VPN

Version: 15.0.0

Platform: macOS

Helper Tool Path: /Library/PrivilegedHelperTools/me.connectify.SMJobBlessHelper

Plist Configuration Path: `/Library/LaunchDaemons/me.connectify.SMJobBlessHelper.plist`

The helper tool, `me.connectify.SMJobBlessHelper`, is installed as a privileged daemon on macOS through the plist configuration file. This setup ensures that the service is started with root privileges and listens for XPC messages, allowing it to perform privileged operations for the Speedify VPN application

# 
