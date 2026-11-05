#!/bin/bash
#
# SPDX-FileCopyrightText: 2026 Zhafron
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

ANDROID_ROOT="${ANDROID_ROOT:?set ANDROID_ROOT to the PixelOS seventeen checkout}"
KEYS_DIR="${KEYS_DIR:?set KEYS_DIR to the directory holding releasekey, platform, shared, media, networkstack, nfc, bluetooth, sdk_sandbox and keys.mk}"
JOBS="${JOBS:-8}"
VARIANT="${VARIANT:-userdebug}"
STOCK_RELEASE_URL="${STOCK_RELEASE_URL:-https://github.com/tickernelz/android_stock_meizu_mblu21/releases/download/mblu21-stock-U01005-20261031}"
HERE="$(cd "$(dirname "$0")" && pwd)"

cd "${ANDROID_ROOT}"

for p in "${HERE}"/patches/build_soong-*.patch; do git -C build/soong apply "$p"; done
for p in "${HERE}"/patches/frameworks_av-*.patch; do git -C frameworks/av apply "$p"; done

keys=vendor/lineage-priv/keys
rm -rf "${keys}"
mkdir -p "${keys}"
for f in "${KEYS_DIR}"/*; do ln -s "$f" "${keys}/$(basename "$f")"; done
ln -s "${ANDROID_ROOT}/build/make/target/product/security/testkey.x509.pem" "${keys}/testkey.x509.pem"
ln -s "${ANDROID_ROOT}/build/make/target/product/security/testkey.pk8" "${keys}/testkey.pk8"

stock_dir="$(mktemp -d)"
trap 'rm -rf "${stock_dir}"' EXIT
curl -fL --retry 3 -o "${stock_dir}/vendor_a.img" "${STOCK_RELEASE_URL}/vendor_a.img"
printf '%s  %s\n' \
    168940cd76345d729c29a1493320ded445aab7912d5a70b201763e5551700c83 vendor_a.img |
    (cd "${stock_dir}" && sha256sum -c -)
(cd device/meizu/mblu21 && ./extract-files.py "${stock_dir}")

export USE_CCACHE=1
export CCACHE_EXEC="${CCACHE_EXEC:-$(command -v ccache)}"
export SOONG_INCREMENTAL_ANALYSIS=false
export SOONG_GOMEMLIMIT="${SOONG_GOMEMLIMIT:-12GiB}"

set +u
source build/envsetup.sh
breakfast mblu21 "${VARIANT}"
set -u

m -j"${JOBS}" pixelos
