PixelOS 17 (Android 17, `CP2A.260605.016`) unofficial for the Meizu mBlu 21 (`mblu21`). Fourth build, first in the `user` variant. Untested label: the owner has not used it for a day yet.

- Build: `custom_mblu21` **`user`**, release-keys, Google apps included. Device [`d496ead`](https://github.com/tickernelz/android_device_meizu_mblu21/commit/d496eadb393c739aa8d2055532de704e0b408cc9) (`seventeen`), vendor `911c071`, kernel `fb003f799`, kernel modules `7bc00d8` (`lineage-24.0`), PixelOS manifest `4a57c83`, `frameworks/native` `b12c597`. Every project's commit is in `all-project-shas.txt`. The zip does not contain `boot`.
- Changes since `20261105-1807`:
  - Variant `user` instead of `userdebug`: `system`, `system_ext` and `product` now report `ro.build.type=user` and a `user/release-keys` fingerprint, consistent with the stock vendor and odm. Left out by the variant: `ro.ota.allow_downgrade`, `procmem`, `su` (unused; root comes from KernelSU), `debug.sf.enable_transaction_tracing=false`, and the `userdebug_or_eng` SELinux rules of backuptool, mediashell_app and recovery. `adb`, `logcat` and `dumpsys` from the shell keep working; there is no `adb root`.
  - The hidden face cameras (ids 30 and 31) come from an odm camera provider (`ICameraProvider/hidden/0`) instead of a `frameworks/av` patch; the build applies no source patch.
  - `frameworks/native`: PixelOS `seventeen` moved from `fe64500` to `b12c597` (UDFPS dim layer lookup).

## Tested on hardware (2026-11-07, installed over 1807 by sideload, data kept)

The phone runs the SukiSU-Ultra built-in kernel with SUSFS and KPM in `boot` (`02ae582a…`, not part of this release) and no KernelSU module.

| Item | 1807 (`userdebug`) | 1706 (`user`) |
|---|---|---|
| `sys.boot_completed`, 3 boots | 50.0 / 48.9 / 48.9 s | 47.7 / 49.0 / 48.5 s |
| SELinux denials (logcat + dmesg), 3 boots | 0 / 0 / 0 | 0 / 0 / 0 |
| Launcher janky frames, one sample about 2 minutes after each boot | 8.67 / 8.55 / 7.86 % | 11.76 / 9.65 / 9.73 % |
| Play Integrity, ROM alone (no integrity module), 3 boots | `NO_INTEGRITY` ×3 | `NO_INTEGRITY` ×3 |
| Speaker / earpiece, 1 kHz tone recorded by the mic, 2 runs | +55.9 / +57.6 dB, +36.8 / +44.6 dB | +58.6 / +62.7 dB, +56.0 / +54.8 dB |

- **Janky frames are higher on 1706** (mean 8.4 % → 10.4 %; 7 more samples on 1706 after boot: 11.08, 10.41, 9.90, 10.56, 12.98, 11.43, 10.19 %). The cause is not isolated: the launcher's compiled code was rebuilt by the background dexopt after the update and 133 packages are still at `verify`, which can explain it, but 1807 was not measured again after its own update for comparison.
- Root: `su` gives `u:r:ksu:s0`, `ksud 4.3.0-r2`, `ksud susfs` `true`/`v2.3.0`/`GKI`/`builtin`, `[AVAILABLE] kpm` with `ksud kpm version` `3584`, SELinux Enforcing, `/data/adb/modules` empty; the former `susfs_guard_lkm` module is gone and not in `/proc/modules`.
- Cameras: back (id 0) and front (id 1) open in Aperture. Face unlock: the face HAL opens camera 30 from the odm provider, enrolment finished with `onEnrollResult(fid=1)` in a lit room, 0 denials; the owner reports unlocking with his face, which was not measured here. In a dark room (1 lux, 2026-11-06 on 1807) enrolment ends with "time limit reached" after 20 s because no face is detected in the frames.
- Wi-Fi 5 GHz connected, Bluetooth turns on, 53 sensors, Telkomsel LTE in service. 0 tombstones, 0 ANRs, 0 app crashes in the boot logs.

Not tested: real calls and SMS, headset, Bluetooth pairing, SD card, MTP on this build, GPS satellite fix, battery life, photo and video capture. `MEETS_DEVICE_INTEGRITY` and `MEETS_STRONG_INTEGRITY` were not attempted and are not reached; with the bootloader unlocked, the phone's hardware attestation says so.

## Files

| File | sha256 |
|---|---|
| `PixelOS_mblu21-17.0-20261106-1706.zip` (join the two parts) | `e0bcb8f11068c5ffab92dcb8843404b3b73b23108d8a6cdd05c81a4e1eba7248` |
| `.part00`, `.part01`, `init_boot.img` | in `SHA256SUMS` |
| `source-shas.txt`, `all-project-shas.txt` | source commits of this build |

Install: see the [README](https://github.com/tickernelz/pixelos_build_mblu21#install). From an earlier PixelOS build of this repository, `adb reboot sideload` and `adb sideload` without wiping; the sideload takes more than 35 minutes.
