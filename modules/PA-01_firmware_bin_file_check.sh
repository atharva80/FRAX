#!/bin/bash

export PRE_THREAD_ENA=0

PA01_firmware_bin_file_check() {
  module_log_init "${FUNCNAME[0]}"

  module_title "Binary firmware file analyzer"
  pre_module_reporter "${FUNCNAME[0]}"

  print_output "[*] Extracting and testing ${ORANGE}$(basename "${FIRMWARE_PATH}")${NC}"
  print_ln

  sub_module_title "File checks"

  print_output "[*] File type analysis"

  local lFILE_DETAILS=""
  lFILE_DETAILS=$(file "${FIRMWARE_PATH}")
  print_output "${lFILE_DETAILS}"

  print_ln

  sub_module_title "Hash calculations"

  print_output "[*] Calculating checksums (MD5, SHA1, SHA512)..."

  if command -v md5sum &> /dev/null; then
    export MD5_CHECKSUM=$(md5sum "${FIRMWARE_PATH}" | awk '{print $1}')
    print_output "[*] MD5 checksum: ${MD5_CHECKSUM}"
  fi

  if command -v sha1sum &> /dev/null; then
    export SHA1_CHECKSUM=$(sha1sum "${FIRMWARE_PATH}" | awk '{print $1}')
    print_output "[*] SHA1 checksum: ${SHA1_CHECKSUM}"
  fi

  if command -v sha512sum &> /dev/null; then
    export SHA512_CHECKSUM=$(sha512sum "${FIRMWARE_PATH}" | awk '{print $1}')
    print_output "[*] SHA512 checksum: ${SHA512_CHECKSUM}"
  fi

  print_ln

  sub_module_title "Entropy analysis"

  entropy_test_binwalk

  print_ln

  sub_module_title "Binwalk firmware detection"

  detect_firmware_type

  print_ln

  sub_module_title "String analysis"

  local lSTRINGS_COUNT=0
  if command -v strings &> /dev/null; then
    lSTRINGS_COUNT=$(strings "${FIRMWARE_PATH}" | wc -l)
    print_output "[*] Strings found: ${lSTRINGS_COUNT}"
  fi

  print_ln

  write_csv_log "FILE_CHECK" "MD5" "${MD5_CHECKSUM}"
  write_csv_log "FILE_CHECK" "SHA1" "${SHA1_CHECKSUM}"
  write_csv_log "FILE_CHECK" "SHA512" "${SHA512_CHECKSUM}"
  write_csv_log "FILE_CHECK" "ENTROPY" "${ENTROPY}"
  write_csv_log "FILE_CHECK" "STRINGS" "${lSTRINGS_COUNT}"

  module_end_log "${FUNCNAME[0]}" 1
}

entropy_test_binwalk() {
  print_output "[*] Entropy testing with binwalk ..."

  export ENTROPY="NA"

  if command -v ent &> /dev/null; then
    local lENT_OUTPUT=$(ent "${FIRMWARE_PATH}" 2>&1)
    export ENTROPY=$(echo "${lENT_OUTPUT}" | grep -i "entropy" | head -1 | awk -F'=' '{print $2}' | awk '{print $1}')

    if [[ -n "${ENTROPY}" && "${ENTROPY}" != "NA" ]]; then
      print_output "[*] Entropy of firmware file:"
      print_output "  ${ORANGE}${ENTROPY}${NC} bits per byte"
      return
    fi
  fi

  if command -v binwalk &> /dev/null; then
    print_output "[*] Using binwalk for entropy analysis (ent not available)..."
    binwalk -E "${FIRMWARE_PATH}" 2>&1 | tee -a "${LOG_FILE}"
    export ENTROPY="CALCULATED_BY_BINWALK"
  else
    print_output "[-] Neither ent nor binwalk available for entropy calculation"
    export ENTROPY="NA"
  fi
}

detect_firmware_type() {
  print_output "[*] Running binwalk analysis for firmware detection..."

  if ! command -v binwalk &> /dev/null; then
    print_output "[-] binwalk not available for detection"
    return
  fi

  local lBINWALK_OUTPUT=$(binwalk "${FIRMWARE_PATH}" 2>&1)

  print_output "[*] Binwalk findings:"
  echo "${lBINWALK_OUTPUT}" | while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      print_output "  $line"
    fi
  done

  # DETECTION: COMPRESSION
  if echo "${lBINWALK_OUTPUT}" | grep -qi "LZMA"; then
    export LZMA_DETECTED=1
    print_output "[+] LZMA compression detected"
    write_csv_log "DETECTION" "COMPRESSION" "LZMA"
  fi

  if echo "${lBINWALK_OUTPUT}" | grep -qi "gzip"; then
    export GZIP_DETECTED=1
    print_output "[+] GZIP compression detected"
    write_csv_log "DETECTION" "COMPRESSION" "GZIP"
  fi

  if echo "${lBINWALK_OUTPUT}" | grep -qi "bzip2"; then
    export BZIP2_DETECTED=1
    print_output "[+] BZIP2 compression detected"
    write_csv_log "DETECTION" "COMPRESSION" "BZIP2"
  fi

  # DETECTION: FILESYSTEM
  if echo "${lBINWALK_OUTPUT}" | grep -qi "squashfs"; then
    export SQUASHFS_DETECTED=1
    print_output "[+] Squashfs filesystem detected"
    write_csv_log "DETECTION" "FILESYSTEM" "SQUASHFS"
  fi

  if echo "${lBINWALK_OUTPUT}" | grep -qi "ext2\|ext3\|ext4"; then
    export EXT_IMAGE=1
    print_output "[+] EXT filesystem detected"
    write_csv_log "DETECTION" "FILESYSTEM" "EXT"
  fi

  if echo "${lBINWALK_OUTPUT}" | grep -qi "cramfs"; then
    export CRAMFS_DETECTED=1
    print_output "[+] CramFS filesystem detected"
    write_csv_log "DETECTION" "FILESYSTEM" "CRAMFS"
  fi

  if echo "${lBINWALK_OUTPUT}" | grep -qi "uimage"; then
    export UBOOT_IMAGE=1
    print_output "[+] U-Boot image detected"
    write_csv_log "DETECTION" "ARCHIVE" "UBOOT"
  fi

  # DETECTION: FIRMWARE TYPE
  if echo "${lBINWALK_OUTPUT}" | grep -qi "vmlinux"; then
    export LINUX_KERNEL=1
    print_output "[+] Linux kernel detected"
    write_csv_log "DETECTION" "OS" "LINUX_KERNEL"
  fi

  if echo "${lBINWALK_OUTPUT}" | grep -qi "zimage"; then
    export ZIMAGE_DETECTED=1
    print_output "[+] Linux kernel (ARM) detected"
    write_csv_log "DETECTION" "OS" "ZIMAGE"
  fi

  # Set RTOS flag if Linux detected
  if [[ ${LINUX_KERNEL:-0} -eq 1 ]] || [[ ${ZIMAGE_DETECTED:-0} -eq 1 ]]; then
    export RTOS=1
    print_output "[+] Real-Time Operating System (RTOS) detected"
  fi
}