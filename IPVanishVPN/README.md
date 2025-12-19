# Product and Version Information

Product: IPVanish VPN

Version: 4.8.0 and earlier

Platform: macOS

Helper Tool Path: `/Library/PrivilegedHelperTools/com.ipvanish.osx.vpnhelper`

Plist Configuration Path: `/Library/LaunchDaemons/com.ipvanish.osx.vpnhelper.plist`

The helper tool, `com.ipvanish.osx.vpnhelper`, is installed as a privileged daemon on macOS through the plist configuration file. This setup ensures that the service is started with root privileges and listens for XPC messages, allowing it to perform privileged operations for the IPVanish VPN application
