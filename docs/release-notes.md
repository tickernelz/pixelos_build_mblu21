PixelOS 17 (Android 17, `CP2A.260605.016`) unofficial for the Meizu mBlu 21 (`mblu21`). **Untested on hardware.**

- Build: `custom_mblu21` `userdebug`, signed with the builder's release keys (`release-keys`), Google apps included.
- Sources: PixelOS `android_manifest` `seventeen`; device [`968c58b`](https://github.com/tickernelz/android_device_meizu_mblu21/commit/968c58bbca18c3000daf8442903b91759a4bc457) (`seventeen`), vendor `911c071`, kernel `fb003f799`, kernel modules `7bc00d8` (`lineage-24.0`).
- Super group `group_unisoc`: 3789 of 5296 MiB used.

## Files

| File | sha256 |
|---|---|
| `PixelOS_mblu21-17.0-20261105-1118.zip` (join the two parts) | `81e4fff1949cb89ac78a613ea9cde1b4468b8a16affad6c9dbfb527f37201cc4` |
| `.part00`, `.part01` | in `SHA256SUMS` |
| `init_boot.img` (unpatched, for KernelSU LKM) | in `SHA256SUMS` |

GitHub limits a release file to 2 GiB and the zip is 2,875,715,605 bytes, so it ships in two parts.

Install, root and the list of untested features: see the [README](https://github.com/tickernelz/pixelos_build_mblu21#install).
