#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: 2026 Zhafron
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

LIBCRYPT_DIR="${LIBCRYPT_DIR:?set LIBCRYPT_DIR to a directory holding libcrypt.so.1}"

exec unshare -Urm --propagation private bash -c '
set -euo pipefail
mount -t overlay overlay -o lowerdir="$1:/usr/lib64" /usr/lib64
uid=$2 gid=$3
shift 3
exec unshare -U --map-user="$uid" --map-group="$gid" "$@"
' ns "${LIBCRYPT_DIR}" "$(id -u)" "$(id -g)" "$@"
