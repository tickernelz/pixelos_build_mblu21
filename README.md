# PixelOS 17 for the Meizu mBlu 21 (M416H) — unofficial

Build files for an unofficial [PixelOS](https://pixelos.net) 17 (Android 17, `CP2A.260605.016`) for the Meizu mBlu 21 (`mblu21`, Unisoc UMS9230, stock vendor Android 13, GKI 5.15). Google apps are part of PixelOS; no add-on is needed.

**Status:** installed on one M416H since 2026-11-05; build `20261106-1706` (variant `user`) runs on it since 2026-11-07, boots with SELinux enforcing. No period of daily use has been recorded yet. What works, what is open and what was not tested yet: [Known issues](#known-issues). Every release with its date and measured results: [Release history](#release-history).

## Sources

| Path | Repository | Branch |
|---|---|---|
| manifest | [PixelOS-AOSP/android_manifest](https://github.com/PixelOS-AOSP/android_manifest) | `seventeen` (base `android-17.0.0_r1`) |
| `device/meizu/mblu21` | [tickernelz/android_device_meizu_mblu21](https://github.com/tickernelz/android_device_meizu_mblu21/tree/seventeen) | `seventeen` |
| `vendor/meizu/mblu21` | [tickernelz/android_vendor_meizu_mblu21](https://github.com/tickernelz/android_vendor_meizu_mblu21) | `lineage-24.0` |
| `kernel/meizu/ums9230` | [tickernelz/android_kernel_meizu_ums9230](https://github.com/tickernelz/android_kernel_meizu_ums9230) | `lineage-24.0` |
| `kernel/meizu/ums9230-modules` | [tickernelz/android_kernel_meizu_ums9230-modules](https://github.com/tickernelz/android_kernel_meizu_ums9230-modules) | `lineage-24.0` |

The `seventeen` device branch differs from `lineage-24.0` in three ways:

- The product is `custom_mblu21` and inherits `vendor/custom/config/common_full_phone.mk`: PixelOS `breakfast` lunches `custom_<device>`.
- `system`, `system_ext` and `product` are erofs, as on stock. Google apps add about 2.5 GB; with ext4 the `group_unisoc` super group (5296 MiB) would overflow. This build uses 3789 MiB of it.
- `TARGET_SCREEN_WIDTH := 720` and the Unisoc face HAL stays the face provider (`TARGET_PROVIDES_FACE_UNLOCK_HAL := true`).

The kernel modules, DTB and DTBO are built from `kernel/meizu/ums9230` and `kernel/meizu/ums9230-modules`. The `boot` image stays stock: it carries the `Image` of Google GKI build `12096863` (`android13-5.15`) byte for byte, because a `boot` built from source has not started on this phone. The bootloader, although unlocked, boots only the Meizu-signed `vbmeta`, which chains `boot` to Meizu's key `d46eb3be`; a `boot` built from source (2026-11-03) stopped at the Meizu logo with an empty pstore. Whether the bootloader rejected it or the kernel failed early was not isolated. See the device tree's [Layout](https://github.com/tickernelz/android_device_meizu_mblu21/tree/seventeen#layout).

## Build

Needs about 150 GB for the shallow checkout and 120 GB for `out`, and about 64 GB of RAM plus swap. Measured for build 1706 (a full Soong analysis after switching to `user`): without a Go memory limit `soong_build` was killed at 44 GB RAM + 8 GB swap; with `GOMEMLIMIT=34GiB` passed to `soong_build` the build peaked at 41.4 GB RAM + 19 GB swap and took 2 h 13 min on 16 cores. Passing that variable needs the three-line host change [`docs/soong-gomemlimit.patch`](docs/soong-gomemlimit.patch) to `build/soong` (`SOONG_GOMEMLIMIT` → `GOMEMLIMIT` for `soong_build`): `git -C build/soong apply ../../pixelos_build_mblu21/docs/soong-gomemlimit.patch`, then run `build.sh` with `SOONG_GOMEMLIMIT=34GiB` in the environment. It changes only the build tool's memory use, not the ROM.

    mkdir pixelos-17 && cd pixelos-17
    repo init -u https://github.com/PixelOS-AOSP/android_manifest.git -b seventeen --git-lfs --depth=1
    mkdir -p .repo/local_manifests
    curl -fL -o .repo/local_manifests/mblu21.xml https://raw.githubusercontent.com/tickernelz/pixelos_build_mblu21/main/mblu21.xml
    repo sync -c --no-tags --no-clone-bundle
    git clone https://github.com/tickernelz/pixelos_build_mblu21 ../pixelos_build_mblu21
    ANDROID_ROOT=$PWD KEYS_DIR=/path/to/keys ../pixelos_build_mblu21/build.sh

`build.sh` builds the PixelOS checkout as synced, without patches: it links `KEYS_DIR` into `vendor/lineage-priv/keys`, extracts the proprietary files from the stock `vendor_a.img` (sha256-checked) and runs `breakfast mblu21 user` and `m pixelos`. The output is `out/target/product/mblu21/PixelOS_mblu21-17.0-<date>.zip`.

- **Keys:** `KEYS_DIR` holds your own `releasekey`, `platform`, `shared`, `media`, `networkstack`, `nfc`, `bluetooth` and `sdk_sandbox` (`.pk8` + `.x509.pem`) and a `keys.mk` with `PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey`. `build.sh` adds the public AOSP `testkey`, which `system/sepolicy` reads for its `[@RELEASE]` tag. Never commit private keys.
- **Hosts without `libcrypt.so.1`** (Fedora 40 and later): the prebuilt perl in `prebuilts/tools-lineage` needs it for the kernel headers archive. Extract `libxcrypt-compat` without installing it and run the build in a user namespace that overlays it on `/usr/lib64`:

      dnf download libxcrypt-compat && rpm2cpio libxcrypt-compat-*.rpm | cpio -idm
      LIBCRYPT_DIR=$PWD/usr/lib64 ./ns.sh env ANDROID_ROOT=... KEYS_DIR=... ./build.sh

## Install

The zip is an A/B OTA signed with the builder's own release key. The phone keeps its stock `boot`, `dtbo` and `vbmeta*`; the OTA writes `init_boot`, `vendor_boot` and the dynamic partitions. The steps assume LineageOS 24.0 (`src4` or later) is running with a root shell (`adb root` or KernelSU).

1. Join the parts and check them:

       cat PixelOS_mblu21-17.0-20261106-1706.zip.part* > PixelOS_mblu21-17.0-20261106-1706.zip
       sha256sum -c SHA256SUMS

2. Get the PixelOS recovery. LineageOS recovery cannot install this zip: PixelOS sets `ro.debuggable=0`, so the payload metadata signature is mandatory and LineageOS recovery only trusts its own key. From LineageOS, apply the OTA with `update_engine` (Updater, or `service call android.os.UpdateEngineService 1 …` with the payload offset and `payload_properties.txt`). This writes the PixelOS `vendor_boot`, which holds the PixelOS recovery, to the other slot and makes that slot active.
3. **Do not wipe and do not boot Android yet.** The phone uses Virtual A/B: the dynamic partitions from step 2 are snapshots that only merge after the first successful boot, and a data wipe before that discards them and returns to the old slot. Reboot straight to recovery: `adb reboot recovery`.
4. In PixelOS recovery choose **Apply update → Apply from ADB** and run `adb sideload PixelOS_mblu21-17.0-20261106-1706.zip`. A sideload writes the partitions directly, without snapshots. `Failed to open /sys/fs/f2fs/features/linear_lookup` is a kernel feature probe, not an error. Wait for `Install completed with status 0`.
5. **Factory reset → Format data.** Required when coming from LineageOS or stock: the platform key and the apps change. This erases all user data.
6. **Reboot system now.** The first boot takes several minutes.

Updating from an earlier PixelOS build of this repository: steps 3 and 4 only (`adb reboot sideload`, then `adb sideload` of the new zip), without step 5. Build `20261106-1706` was installed this way over `20261105-1807` with data kept; the sideload took more than 35 minutes and the host progress stayed at `~47%` while the phone wrote the partitions, so do not interrupt it.

## Root

Two ways, both measured on this phone; full steps in [android_kernel_meizu_mblu21 ROOT.md](https://github.com/tickernelz/android_kernel_meizu_mblu21/blob/main/docs/ROOT.md).

- **Built-in kernel (what the test phone runs on build `20261106-1706`):** the `Image` of `boot-sukisu-ultra-kpm` from the `sukisu-ultra-20261106-untested` pre-release, re-signed with your own key against the stock `boot`, written to `boot_<slot>`. SukiSU-Ultra, SUSFS and KPM are in the kernel; no module is needed (`ksud susfs implementation` reports `builtin`). The ROM zip does not touch `boot`, so the kernel stays across ROM updates.
- **LKM:** patch this build's `init_boot.img` (also a release asset) with `ksud boot-patch -b init_boot.img -o <directory>` (SukiSU Ultra 4.3.0, KMI `android13-5.15`), write the result to `init_boot_<slot>`, then install the `susfs_guard_lkm` module. A build whose stock `init_boot` differs needs a new patch: 1507 and 1807 share `738c8151…`, 1706 has `4d9a137f…`.

## Known issues

State on build `20261106-1706` unless a row names another build. A row that says "not tested" has not been checked on PixelOS yet, and an area without a row has not been tested on PixelOS; LineageOS 24.0 results for the same vendor, kernel and modules are in the device tree's [Status](https://github.com/tickernelz/android_device_meizu_mblu21/tree/seventeen#status).

| Area | State | Evidence |
|---|---|---|
| Mobile data, APN | works on Telkomsel (510/10) | the `internet` APN is preferred (`default_preferred_apn_name_string`); the first default APN, `telkomsel`, did not connect in the setup wizard on build 1118. Other Indonesian operators: not tested |
| Navigation in the setup wizard | fixed in the tree, first boot not checked | gesture navigation is the default (`androidboot.vendor.overlay.theme` in `/proc/bootconfig`); with three-button navigation the wizard showed only a back button on build 1118. Not yet seen on a first boot after Format data |
| Display 90 Hz | works | 90 Hz by default; the Smooth display switch caps it at 60 Hz |
| GPS | not tested outdoors | the Unisoc UMW2652 GNSS HAL runs and network location works; no satellite fix has been recorded yet |
| Bluetooth | turns on; pairing not tested | `cmd bluetooth_manager enable` returns `Success` on build 1706; no device was paired |
| Headset jack | not tested | the `Headset Jack` input device supports the headphone and microphone insert switches; no headset was plugged in |
| SD card | not tested | no SD volume appeared; whether a card was inserted was not checked |
| Battery | one report, not repeated | build 1118 reported `health=overheat` once at 42.9 °C; later `health=Good` at 38.8 °C. Battery life not measured |
| Calls and SMS | registration only | Telkomsel LTE `IN_SERVICE` for voice and data on build 1706; no call or SMS was placed on PixelOS. Calls work on LineageOS 24.0 with the same vendor, kernel and modules (2026-11-04) |
| Camera | both cameras open; photo and video not tested | build 1706: Aperture opens camera 0 (back) and 1 (front), 74 and 106 frames in the log |
| Audio | speaker and earpiece play | build 1706, 1 kHz tone recorded by the microphone: speaker +58.6/+62.7 dB, earpiece +56.0/+54.8 dB over silence. Calls and headset not tested |
| Wi-Fi, touch, sensors | work | build 1706: Wi-Fi 5 GHz connected, touch, 53 sensors listed |
| MTP | not checked on build 1706 | the USB function was `adb` only during testing; MTP worked on build 1507 |
| VoLTE | network limitation | measured on build 1118 and on LineageOS 24.0: Telkomsel reports IMS voice over PS not supported (`mVopsSupport = 3`), as on stock |
| Face unlock | enrolment completes | build 1706: the face HAL opens hidden camera 30 from the odm camera provider, enrolment ended with `onEnrollResult(fid=1)` and "Done" in a lit room, 0 SELinux denials. The owner reports unlocking with his face; it was not measured here. In a dark room (1 lux) enrolment times out after 20 s because no face is detected in the frames |
| Fingerprint | not tested | the HAL runs; the fingerprint sensor of the test phone is broken in hardware |
| Play Integrity | ROM alone: `NO_INTEGRITY` | measured on builds 1807 and 1706 without any integrity module, 3 boots each; see [Release history](#release-history) |

## Release history

Play Integrity results are raw verdicts from a Play Integrity checker app on the release, with the root and integrity modules named in the row. Neither is part of the ROM.

| Date (UTC) | Release | Device commit | On hardware | Play Integrity (measured) |
|---|---|---|---|---|
| 2026-11-05 | [`PixelOS-17.0-20261105-UNOFFICIAL-mblu21`](https://github.com/tickernelz/pixelos_build_mblu21/releases/tag/PixelOS-17.0-20261105-UNOFFICIAL-mblu21) (build 1118) | [`968c58b`](https://github.com/tickernelz/android_device_meizu_mblu21/commit/968c58bbca18c3000daf8442903b91759a4bc457) | published before testing; installed and booted later the same day | not measured |
| 2026-11-05 | [`PixelOS-17.0-20261105-1507-UNOFFICIAL-mblu21`](https://github.com/tickernelz/pixelos_build_mblu21/releases/tag/PixelOS-17.0-20261105-1507-UNOFFICIAL-mblu21) | [`5fc7dc0`](https://github.com/tickernelz/android_device_meizu_mblu21/commit/5fc7dc073cdda895566368058e57d3fdbe3ecb65) | boots, SELinux enforcing; see [release notes](docs/release-notes.md) | with KernelSU LKM, Tricky Store 1.4.1, Play Integrity Fix v19 and Tricky Store's built-in software keybox: `deviceRecognitionVerdict: ["MEETS_BASIC_INTEGRITY"]`, `appRecognitionVerdict: PLAY_RECOGNIZED`, `appLicensingVerdict: LICENSED` on 2 consecutive boots. The same verdicts on 3 consecutive boots with a third-party ecdsa-only keybox instead. Without root: not measured |
| 2026-11-05 | [`PixelOS-17.0-20261105-1807-UNOFFICIAL-mblu21`](https://github.com/tickernelz/pixelos_build_mblu21/releases/tag/PixelOS-17.0-20261105-1807-UNOFFICIAL-mblu21) | [`220cb65`](https://github.com/tickernelz/android_device_meizu_mblu21/commit/220cb65e9dba1c5493ba5eb0f59c5d5308b15d6c) | boots, SELinux enforcing, 0 non-app denials over boot plus 10 minutes of scripted use; 2026-11-06: boot 50.0/48.9/48.9 s, 0 denials on 3 boots | ROM alone with the SukiSU-Ultra built-in kernel and no module (2026-11-06, 3 boots): `NO_INTEGRITY` each time |
| 2026-11-07 | [`PixelOS-17.0-20261106-1706-UNOFFICIAL-mblu21-untested`](https://github.com/tickernelz/pixelos_build_mblu21/releases/tag/PixelOS-17.0-20261106-1706-UNOFFICIAL-mblu21-untested) (variant `user`) | [`d496ead`](https://github.com/tickernelz/android_device_meizu_mblu21/commit/d496eadb393c739aa8d2055532de704e0b408cc9) | installed over 1807 without wiping data; boot 47.7/49.0/48.5 s, 0 denials on 3 boots; see [release notes](docs/release-notes.md) | ROM alone, same setup (3 boots): `NO_INTEGRITY` each time, the same as 1807 |

## Credits and AI assistance

Sources and credits are listed in the device tree's [Credits](https://github.com/tickernelz/android_device_meizu_mblu21/tree/seventeen#credits). Most of this repository, the device tree and the mblu21 commits on top of the imported kernel sources (8 in `android_kernel_meizu_ums9230`, the import and fix commits in `android_kernel_meizu_ums9230-modules`) were written with AI coding assistants (LLM agents) at Zhafron's direction and tested on his phone; see [History and AI assistance](https://github.com/tickernelz/android_device_meizu_mblu21/tree/seventeen#history-and-ai-assistance).

## License

Apache-2.0. See [LICENSE](LICENSE).
