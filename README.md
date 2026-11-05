# PixelOS 17 for the Meizu mBlu 21 (M416H) — unofficial

Build files for an unofficial [PixelOS](https://pixelos.net) 17 (Android 17, `CP2A.260605.016`) for the Meizu mBlu 21 (`mblu21`, Unisoc UMS9230, stock vendor Android 13, GKI 5.15). Google apps are part of PixelOS; no add-on is needed.

**Status: untested on hardware.** The same device, vendor and kernel trees boot as LineageOS 24.0 on this phone (`lineage-24.0-20261105-UNOFFICIAL-mblu21-src4`); this PixelOS build has not been booted yet. See [Not tested](#not-tested).

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

## Build

Needs about 150 GB for the shallow checkout and 120 GB for `out`, and about 40 GB of RAM plus swap.

    mkdir pixelos-17 && cd pixelos-17
    repo init -u https://github.com/PixelOS-AOSP/android_manifest.git -b seventeen --git-lfs --depth=1
    mkdir -p .repo/local_manifests
    curl -fL -o .repo/local_manifests/mblu21.xml https://raw.githubusercontent.com/tickernelz/pixelos_build_mblu21/main/mblu21.xml
    repo sync -c --no-tags --no-clone-bundle
    git clone https://github.com/tickernelz/pixelos_build_mblu21 ../pixelos_build_mblu21
    ANDROID_ROOT=$PWD KEYS_DIR=/path/to/keys ../pixelos_build_mblu21/build.sh

`build.sh` applies the two patches in `patches/`, links `KEYS_DIR` into `vendor/lineage-priv/keys`, extracts the proprietary files from the stock `vendor_a.img` (sha256-checked) and runs `breakfast mblu21 userdebug` and `m pixelos`. The output is `out/target/product/mblu21/PixelOS_mblu21-17.0-<date>.zip`.

- **Keys:** `KEYS_DIR` holds your own `releasekey`, `platform`, `shared`, `media`, `networkstack`, `nfc`, `bluetooth` and `sdk_sandbox` (`.pk8` + `.x509.pem`) and a `keys.mk` with `PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/lineage-priv/keys/releasekey`. `build.sh` adds the public AOSP `testkey`, which `system/sepolicy` reads for its `[@RELEASE]` tag. Never commit private keys.
- **Hosts without `libcrypt.so.1`** (Fedora 40 and later): the prebuilt perl in `prebuilts/tools-lineage` needs it for the kernel headers archive. Extract `libxcrypt-compat` without installing it and run the build in a user namespace that overlays it on `/usr/lib64`:

      dnf download libxcrypt-compat && rpm2cpio libxcrypt-compat-*.rpm | cpio -idm
      LIBCRYPT_DIR=$PWD/usr/lib64 ./ns.sh env ANDROID_ROOT=... KEYS_DIR=... ./build.sh

## Install

The zip is an A/B OTA signed with the builder's own release key. The phone keeps its stock `boot`, `dtbo` and `vbmeta*`; the OTA writes `init_boot`, `vendor_boot` and the dynamic partitions. The steps assume LineageOS 24.0 (`src4` or later) is running with a root shell (`adb root` or KernelSU).

1. Join the parts and check them:

       cat PixelOS_mblu21-17.0-20261105-1807.zip.part* > PixelOS_mblu21-17.0-20261105-1807.zip
       sha256sum -c SHA256SUMS

2. Get the PixelOS recovery. LineageOS recovery cannot install this zip: PixelOS sets `ro.debuggable=0`, so the payload metadata signature is mandatory and LineageOS recovery only trusts its own key. From LineageOS, apply the OTA with `update_engine` (Updater, or `service call android.os.UpdateEngineService 1 …` with the payload offset and `payload_properties.txt`). This writes the PixelOS `vendor_boot`, which holds the PixelOS recovery, to the other slot and makes that slot active.
3. **Do not wipe and do not boot Android yet.** The phone uses Virtual A/B: the dynamic partitions from step 2 are snapshots that only merge after the first successful boot, and a data wipe before that discards them and returns to the old slot. Reboot straight to recovery: `adb reboot recovery`.
4. In PixelOS recovery choose **Apply update → Apply from ADB** and run `adb sideload PixelOS_mblu21-17.0-20261105-1807.zip`. A sideload writes the partitions directly, without snapshots. `Failed to open /sys/fs/f2fs/features/linear_lookup` is a kernel feature probe, not an error. Wait for `Install completed with status 0`.
5. **Factory reset → Format data.** Required when coming from LineageOS or stock: the platform key and the apps change. This erases all user data.
6. **Reboot system now.** The first boot takes several minutes.

## Root

KernelSU in LKM mode, the method proven on LineageOS src4: patch this build's `init_boot.img` (also a release asset) with `ksud boot-patch -b init_boot.img -o <directory>` (SukiSU Ultra 4.3.0, KMI `android13-5.15`), write the result to `init_boot_<slot>`, then install the `susfs_guard_lkm` module. A built-in KernelSU kernel cannot ship: the bootloader keeps `boot` verified against Meizu's key.

## Not tested

Nothing has been checked on hardware yet: boot, display, touch, Wi-Fi, Bluetooth, mobile data, calls, SMS, VoLTE, camera, face unlock, fingerprint, audio, GPS, MTP, charging, SELinux enforcing, the PixelOS updater and the root steps above.

## License

Apache-2.0. See [LICENSE](LICENSE).
