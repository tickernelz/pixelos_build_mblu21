PixelOS 17 (Android 17, `CP2A.260605.016`) unofficial for the Meizu mBlu 21 (`mblu21`). Second build.

- Build: `custom_mblu21` `userdebug`, release-keys, Google apps included. Device [`5fc7dc0`](https://github.com/tickernelz/android_device_meizu_mblu21/commit/5fc7dc073cdda895566368058e57d3fdbe3ecb65) (`seventeen`), vendor `911c071`, kernel `fb003f799`, kernel modules `7bc00d8` (`lineage-24.0`).
- Changes since `20261105-1118`:
  - Telkomsel (510/10) uses the `internet` APN until the user picks one; the first default APN, `telkomsel`, did not connect in the setup wizard.
  - Gesture navigation is the first-boot default. With three-button navigation the setup wizard showed only a back button in the bottom-right corner. Takes effect after Format data.
  - Settings shows the Smooth display switch. 90 Hz stays the default; turning the switch off caps the display at 60 Hz.

## Tested on hardware (05-11, build 1507 over 1118, no wipe)
Boot, SELinux Enforcing, 0 kernel panics and 0 app crashes after boot, display 90 Hz (60 Hz with Smooth display off), touch, Wi-Fi, Telkomsel LTE data, MTP, 49 sensors, camera opens, KernelSU LKM (SukiSU 4.3.0) with `susfs_guard_lkm` v2.3.0. VoLTE: Telkomsel reports VoPS not supported (network, also on stock).

Not tested yet: real calls and SMS, headset, Bluetooth pairing, SD card, fingerprint and face enrolment, GPS fix, battery life.

## Files

| File | sha256 |
|---|---|
| `PixelOS_mblu21-17.0-20261105-1507.zip` (join the two parts) | `c88bc186054d34af19b16ee2916746c0c741abb79cfec618925886d06d78ad1e` |
| `.part00`, `.part01`, `init_boot.img` | in `SHA256SUMS` |

GitHub limits a release file to 2 GiB, so the zip ships in two parts. Install and root: see the [README](https://github.com/tickernelz/pixelos_build_mblu21#install).
