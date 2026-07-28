# Capabilities and Background Modes

Every shipping entitlement and background mode must have a current runtime owner. Debug and Release intentionally use separate entitlement files so each configuration can be validated independently.

| Capability or mode | Runtime owner | Why BeatClikr needs it |
| --- | --- | --- |
| `audio` background mode | Playback coordinator and audio session | Keeps metronome and playlist audio running when the app is backgrounded or the device locks. |
| `remote-notification` background mode | SwiftData/CloudKit synchronization | Allows CloudKit-backed practice, song, and playlist data to receive remote-change delivery. |
| `aps-environment` | SwiftData/CloudKit synchronization | Enables the silent push channel used by CloudKit change notifications. Distribution signing replaces the development value as appropriate for the provisioning profile. It is not used for marketing or server-originated user notifications. |
| `com.apple.developer.icloud-container-identifiers` | SwiftData model container | Selects `iCloud.com.bfunkstudios.beatclikr` for CloudKit persistence. |
| `com.apple.developer.icloud-services` (`CloudKit`) | SwiftData model container | Enables CloudKit-backed persistence and synchronization. |
| `com.apple.developer.ubiquity-kvstore-identifier` | `UserDefaultsService` | Synchronizes preferences such as reminder settings across the user’s devices. |
| `com.apple.security.app-sandbox` | Mac Catalyst target | Keeps the Catalyst app in the required application sandbox. |

Local practice reminders use `UNUserNotificationCenter`. They do not require a push entitlement because their requests are scheduled entirely on-device.

The user-selected-file entitlement was removed in Milestone 6.1 because BeatClikr has no document picker, security-scoped bookmark, import, or export feature.

## Release validation

For both Debug and Release:

1. Build the product and inspect its processed `Info.plist`.
2. Inspect the signed application entitlements with `codesign`.
3. Confirm the product contains only runtime assets, localized strings, sound files, and required metadata.

Debug and Release source entitlements and processed background modes were audited in Milestone 6.1. Simulator signatures intentionally contain no effective capabilities. The unsigned device archive proved the payload layout, but not provisioning-controlled values.

For the next distribution archive, repeat the entitlement inspection on the signed `.app` because the provisioning profile controls the final `aps-environment` value. This is the remaining Milestone 6.1 acceptance check.
