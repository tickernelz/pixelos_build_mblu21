PixelOS 17 (Android 17, `CP2A.260605.016`) unofficial for the Meizu mBlu 21 (`mblu21`). Third build.

- Build: `custom_mblu21` `userdebug`, release-keys, Google apps included. Device [`220cb65`](https://github.com/tickernelz/android_device_meizu_mblu21/commit/220cb65e9dba1c5493ba5eb0f59c5d5308b15d6c) (`seventeen`), vendor `911c071`, kernel `fb003f799`, kernel modules `7bc00d8` (`lineage-24.0`); boot is the stock Meizu kernel.
- Changes since `20261105-1507`:
  - SELinux: `system_server` may read `net.pixelos.version` and `persist.sys.pihooks.disable.` (PixelOS reads both there); the unused cache partition is labelled `cache_block_device` and the boot-time format attempt from the stock vendor fstab stays denied without a log entry; Android System Intelligence reading `/proc/version` stays denied without a log entry.
  - `lineage.updater.uri` removed (PixelOS has no updater on unofficial devices).
- Since `20261105-1507`: Telkomsel prefers the `internet` APN, gesture navigation is the default for users who have not picked a mode, and Settings shows the Smooth display switch (90 Hz default).

## Tested on hardware (06-11, OTA over 1507, no wipe)
Boot, SELinux Enforcing, **0 non-app SELinux denials and 0 app crashes over boot plus 10 minutes of scripted use** (Settings, camera, Wi-Fi, Bluetooth, display and location screens, browser, notification shade), 0 kernel panics, KernelSU LKM (SukiSU v4.3.0-r2) with `susfs_guard_lkm` v2.3.0, Telkomsel LTE, Wi-Fi, display 90 Hz, cache partition labelled `cache_block_device`.

Not tested yet: real calls and SMS, headset, Bluetooth pairing, SD card, fingerprint and face enrolment, GPS satellite fix, battery life. VoLTE: Telkomsel reports VoPS not supported (network, also on stock).

## Files

| File | sha256 |
|---|---|
| `PixelOS_mblu21-17.0-20261105-1807.zip` (join the two parts) | `0cc4f0a1de59121b06357d126cb3edb222cf19d069a70f2a81bce7b09af3744f` |
| `.part00`, `.part01`, `init_boot.img` | in `SHA256SUMS` |

GitHub limits a release file to 2 GiB, so the zip ships in two parts. Install and root: see the [README](https://github.com/tickernelz/pixelos_build_mblu21#install); root images for this build are in [`mblu21-pixelos-root-20261105`](https://github.com/tickernelz/android_kernel_meizu_mblu21/releases/tag/mblu21-pixelos-root-20261105) (same `init_boot` as 1507).
