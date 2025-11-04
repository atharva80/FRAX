#!/bin/bash

export PRE_THREAD_ENA=0

PA05_package_extractor() {
  module_log_init "${FUNCNAME[0]}"

  module_title "Package extractor module"
  pre_module_reporter "${FUNCNAME[0]}"

  if [[ "${DISABLE_DEEP:-0}" -eq 1 ]]; then
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  local lDISK_SPACE_CRIT=0
  local lNEG_LOG=0
  local lFILES_PRE_PACKAGE=0
  local lFILES_POST_PACKAGE_ARR=()

  export WAIT_PIDS_PA05=()

  # Initialize ROOT_PATH if not set
  if [[ -z "${ROOT_PATH:-}" ]]; then
    export ROOT_PATH=()
  fi

  print_output "[*] Package extraction module"
  print_output "[*] ROOT_PATH count: ${#ROOT_PATH[@]}"
  print_output "[*] RTOS status: ${RTOS:-0}"

  # Only proceed if we have root paths detected and firmware extracted
  if [[ ${#ROOT_PATH[@]} -gt 0 ]] && [[ "${RTOS:-0}" -eq 0 ]]; then
    print_output "[*] Found ${#ROOT_PATH[@]} root paths - proceeding with package extraction"

    lFILES_PRE_PACKAGE=$(find "${FIRMWARE_PATH_CP}" -type f ! -name "*.raw" 2>/dev/null | wc -l)
    print_output "[*] Files before package extraction: ${lFILES_PRE_PACKAGE}"

    deb_extractor
    ipk_extractor
    apk_extractor
    rpm_extractor

    lFILES_POST_PACKAGE_ARR=()
    mapfile -t lFILES_POST_PACKAGE_ARR < <(find "${FIRMWARE_PATH_CP}" -xdev -type f ! -name "*.raw" 2>/dev/null)

    if [[ "${#lFILES_POST_PACKAGE_ARR[@]}" -gt "${lFILES_PRE_PACKAGE}" ]]; then
      sub_module_title "Package extraction results"
      print_ln
      print_output "[+] Extraction successful!"
      print_output "[*] Files before: ${lFILES_PRE_PACKAGE}"
      print_output "[*] Files after: ${#lFILES_POST_PACKAGE_ARR[@]}"
      lNEG_LOG=1
    fi
  else
    print_output "[*] Package extraction: Skipped"
    print_output "[*] Reason: No root directories detected or RTOS already set"
  fi

  module_end_log "${FUNCNAME[0]}" "${lNEG_LOG}"
}

deb_extractor() {
  sub_module_title "DEB archive extraction"
  local lDEB_ARCHIVES_ARR=()
  local lFILES_AFTER_DEB=0
  local lR_PATH=""
  local lDEB=""

  print_output "[*] Searching for DEB archives..."
  mapfile -t lDEB_ARCHIVES_ARR < <(find "${FIRMWARE_PATH_CP}" -xdev -type f \( -name "*.deb" -o -name "*.udeb" \) 2>/dev/null | head -100)

  if [[ "${#lDEB_ARCHIVES_ARR[@]}" -gt 0 ]]; then
    print_output "[+] Found ${#lDEB_ARCHIVES_ARR[@]} DEB files"

    for lR_PATH in "${ROOT_PATH[@]}"; do
      for lDEB in "${lDEB_ARCHIVES_ARR[@]}"; do
        if [[ -f "${lDEB}" ]]; then
          print_output "[*] Extracting $(basename "${lDEB}")"
          dpkg-deb --extract "${lDEB}" "${lR_PATH}" 2>/dev/null || true
        fi
      done
    done
  else
    print_output "[-] No DEB files found"
  fi
}

ipk_extractor() {
  sub_module_title "IPK archive extraction"
  local lIPK_ARCHIVES_ARR=()
  local lR_PATH=""
  local lIPK=""

  print_output "[*] Searching for IPK archives..."
  mapfile -t lIPK_ARCHIVES_ARR < <(find "${FIRMWARE_PATH_CP}" -xdev -type f -name "*.ipk" 2>/dev/null | head -100)

  if [[ "${#lIPK_ARCHIVES_ARR[@]}" -gt 0 ]]; then
    print_output "[+] Found ${#lIPK_ARCHIVES_ARR[@]} IPK files"
    mkdir -p "${LOG_DIR}/ipk_tmp" 2>/dev/null

    for lR_PATH in "${ROOT_PATH[@]}"; do
      for lIPK in "${lIPK_ARCHIVES_ARR[@]}"; do
        if [[ -f "${lIPK}" ]]; then
          print_output "[*] Extracting $(basename "${lIPK}")"
          tar zxpf "${lIPK}" --directory "${LOG_DIR}/ipk_tmp" 2>/dev/null || true
          if [[ -f "${LOG_DIR}/ipk_tmp/data.tar.gz" ]]; then
            tar xzf "${LOG_DIR}/ipk_tmp/data.tar.gz" --directory "${lR_PATH}" 2>/dev/null || true
          fi
          rm -rf "${LOG_DIR}/ipk_tmp/"* 2>/dev/null || true
        fi
      done
    done

    rm -rf "${LOG_DIR}/ipk_tmp" 2>/dev/null || true
  else
    print_output "[-] No IPK files found"
  fi
}

apk_extractor() {
  sub_module_title "APK archive extraction"
  local lAPK_ARCHIVES_ARR=()
  local lR_PATH=""
  local lAPK=""

  print_output "[*] Searching for APK archives..."
  mapfile -t lAPK_ARCHIVES_ARR < <(find "${FIRMWARE_PATH_CP}" -xdev -type f -name "*.apk" 2>/dev/null | head -100)

  if [[ "${#lAPK_ARCHIVES_ARR[@]}" -gt 0 ]]; then
    print_output "[+] Found ${#lAPK_ARCHIVES_ARR[@]} APK files"

    for lR_PATH in "${ROOT_PATH[@]}"; do
      for lAPK in "${lAPK_ARCHIVES_ARR[@]}"; do
        if [[ -f "${lAPK}" ]]; then
          print_output "[*] Extracting $(basename "${lAPK}")"
          unzip -o -d "${lR_PATH}" "${lAPK}" 2>/dev/null || true
        fi
      done
    done
  else
    print_output "[-] No APK files found"
  fi
}

rpm_extractor() {
  sub_module_title "RPM archive extraction"
  local lRPM_ARCHIVES_ARR=()
  local lR_PATH=""
  local lRPM=""

  print_output "[*] Searching for RPM archives..."
  mapfile -t lRPM_ARCHIVES_ARR < <(find "${FIRMWARE_PATH_CP}" -xdev -type f -name "*.rpm" 2>/dev/null | head -100)

  if [[ "${#lRPM_ARCHIVES_ARR[@]}" -gt 0 ]]; then
    print_output "[+] Found ${#lRPM_ARCHIVES_ARR[@]} RPM files"

    for lR_PATH in "${ROOT_PATH[@]}"; do
      for lRPM in "${lRPM_ARCHIVES_ARR[@]}"; do
        if [[ -f "${lRPM}" ]]; then
          print_output "[*] Extracting $(basename "${lRPM}")"
          rpm2cpio "${lRPM}" 2>/dev/null | cpio -D "${lR_PATH}" -idm 2>/dev/null || true
        fi
      done
    done
  else
    print_output "[-] No RPM files found"
  fi
}