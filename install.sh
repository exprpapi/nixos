#!/usr/bin/env bash
PS4="\e[34m[$(basename "${0}")"':${FUNCNAME[0]:+${FUNCNAME[0]}():}${LINENO:-}]: \e[0m'
IFS=$'\n\t'
set -euxo pipefail

DISK=''
BOOT_PART=''
ROOT_PART=''
BOOT_PART_NAME='Boot Partition'
ROOT_PART_NAME='Root Partition'
BOOT_PART_TYPE_GUID='c12a7328-f81f-11d2-ba4b-00a0c93ec93b'
ROOT_PART_TYPE_GUID='4f68bce3-e8cd-4db1-96e7-fbcaf984b709'
LABEL_BOOT='boot'
LABEL_ROOT='root'
LABEL_LUKS='luks'

die() {
  if [[ "$#" -gt 0 ]]; then
    printf '\e[31m%s\e[0m\n' "${@}" >&2
  fi
  exit 1
}

assert_blockfile() {
  if [[ "$#" != 1 || ! -b "${1}" ]]; then
    die "${FUNCNAME[0]}()"
  fi
}

partition() {
  if [[ "$#" -lt 1 ]]; then
    die "${FUNCNAME[0]}(): invalid argc"
  fi

  DISK="${1}"
  assert_blockfile "${DISK}"

  sudo sgdisk --zap-all "${DISK}"

  sudo sgdisk \
    --new='0:0:+1GiB' \
    --change-name="0:${BOOT_PART_NAME}" \
    --typecode="0:${BOOT_PART_TYPE_GUID}" \
    "${DISK}"

  sudo sgdisk \
    --new='0:0:' \
    --change-name="0:${ROOT_PART_NAME}" \
    --typecode="0:${ROOT_PART_TYPE_GUID}" \
    "${DISK}"

  local partitions="$(\
    lsblk -l "${DISK}"
    | grep part
    | cut -d ' ' -f 1
    | head -n 2
  )"

  BOOT_PART="/dev/$(head -n 1 <<< "${partitions}")"
  ROOT_PART="/dev/$(tail -n 1 <<< "${partitions}")"

  assert_blockfile "${BOOT_PART}"
  assert_blockfile "${ROOT_PART}"

  if [[ "${BOOT_PART}" == "${ROOT_PART}" ]]; then
    die "${FUNCNAME[0]}(): failed to create two partitions"
  fi
}

format() {
  sudo mkfs.fat -F 32 \
    -n "${LABEL_BOOT}" \
    "${BOOT_PART}"

  sudo cryptsetup luksFormat \
    --batch-mode \
    --verify-passphrase \
    --verbose \
    --label "${LABEL_LUKS}" \
    "${ROOT_PART}"

  sudo cryptsetup luksOpen \
    "${ROOT_PART}" \
    "${LABEL_LUKS}"

  sudo mkfs.ext4 \
    -L "${LABEL_ROOT}" \
    "/dev/mapper/${LABEL_LUKS}"
}

install() {
  sudo mount --mkdir "/dev/disk/by-label/${LABEL_ROOT}" '/mnt'
  sudo mount --mkdir "/dev/disk/by-label/${LABEL_BOOT}" '/mnt/boot'
  sudo rsync -r './nixos' '/mnt/etc'
  sudo nixos-install
}

main() {
  if [[ "${#}" != '1' ]]; then
    die 'argc != 1, no disk passed'
  fi
  local disk="${1}"
  partition "${disk}"
  format
  sleep 1 # labels need to propagate
  install
}

main "$@"
