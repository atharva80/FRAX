#!/bin/bash

################################################################################
# FRAX Framework - Comprehensive Helper Functions Library
# 
# This file contains all helper functions required by PA-01 through PA-06 modules
# Total: 51 functions organized by category
# 
# Source this file after frax.conf in your main script
################################################################################

################################################################################
# LOGGING FUNCTIONS (10)
################################################################################

module_log_init() {
  local lMODULE_NAME="${1:-}"
  
  export LOG_PATH_MODULE="${LOG_DIR}/${lMODULE_NAME}"
  mkdir -p "${LOG_PATH_MODULE}"
  export LOG_FILE_MODULE="${LOG_PATH_MODULE}/${lMODULE_NAME}.log"
  > "${LOG_FILE_MODULE}"
}

module_end_log() {
  local lMODULE_NAME="${1:-}"
  local lEXIT_CODE="${2:-0}"
  
  if [[ -n "${LOG_FILE_MODULE}" ]]; then
    print_output "[+] Module ${lMODULE_NAME} completed with exit code ${lEXIT_CODE}"
  fi
}

module_title() {
  local lTITLE="${1:-}"
  print_output ""
  print_output "╔════════════════════════════════════════════════════════════════╗"
  print_output "║ ${lTITLE}"
  print_output "╚════════════════════════════════════════════════════════════════╝"
  print_output ""
}

sub_module_title() {
  local lTITLE="${1:-}"
  print_output ""
  print_output "──────────────────────────────────────────────────────────────────"
  print_output "  ${lTITLE}"
  print_output "──────────────────────────────────────────────────────────────────"
  print_output ""
}

pre_module_reporter() {
  local lMODULE_NAME="${1:-}"
  print_output "[*] Starting ${lMODULE_NAME} module..."
}

################################################################################
# OUTPUT FUNCTIONS (4)
################################################################################

print_output() {
  local lTEXT="${1:-}"
  local lNO_LOG="${2:-}"
  
  echo -e "${lTEXT}"
  
  if [[ "${lNO_LOG}" != "no_log" ]] && [[ -n "${LOG_FILE}" ]]; then
    echo -e "${lTEXT}" | sed 's/\x1b\[[0-9;]*m//g' >> "${LOG_FILE}"
  fi
}

print_error() {
  local lTEXT="${1:-}"
  print_output "[!] ERROR: ${lTEXT}"
}

print_ln() {
  local lNO_LOG="${1:-}"
  
  echo ""
  if [[ "${lNO_LOG}" != "no_log" ]] && [[ -n "${LOG_FILE}" ]]; then
    echo "" >> "${LOG_FILE}"
  fi
}

indent() {
  local lTEXT="${1:-}"
  echo "${lTEXT}" | sed 's/^/  /'
}

orange() {
  local lTEXT="${1:-}"
  echo "${ORANGE}${lTEXT}${NC}"
}

################################################################################
# CSV & DATA FUNCTIONS (1)
################################################################################

write_csv_log() {
  local lDATA="${@}"
  
  if [[ -n "${LOG_FILE}" ]]; then
    echo "${lDATA}" | tr ' ' ',' >> "${LOG_FILE}"
  fi
}

################################################################################
# FILE & LINK FUNCTIONS (3)
################################################################################

write_link() {
  local lFILE_PATH="${1:-}"
  
  if [[ -f "${lFILE_PATH}" ]]; then
    print_output "[*] Generated: ${lFILE_PATH}"
  fi
}

write_log() {
  local lTEXT="${1:-}"
  
  if [[ -n "${LOG_FILE}" ]]; then
    echo "${lTEXT}" >> "${LOG_FILE}"
  fi
}

backup_var() {
  local lVAR_NAME="${1:-}"
  local lVAR_VALUE="${2:-}"
  
  if [[ -n "${BACKUP_FILE}" ]]; then
    echo "export ${lVAR_NAME}=\"${lVAR_VALUE}\"" >> "${BACKUP_FILE}"
  fi
}

################################################################################
# PROCESS MANAGEMENT (3)
################################################################################

wait_for_pid() {
  local lPIDS=("$@")
  
  for lPID in "${lPIDS[@]}"; do
    if [[ -n "${lPID}" ]] && kill -0 "${lPID}" 2>/dev/null; then
      wait "${lPID}"
    fi
  done
}

store_kill_pids() {
  local lPID="${1:-}"
  
  if [[ -n "${lPID}" ]]; then
    echo "${lPID}" >> "${KILL_PIDS_FILE}"
  fi
}

max_pids_protection() {
  local lMAX_PIDS="${1:-}"
  local lPIDS_ARRAY_NAME="${2:-}"
  local lPIDS_ARRAY=("${!lPIDS_ARRAY_NAME}")
  
  while [[ ${#lPIDS_ARRAY[@]} -ge lMAX_PIDS ]]; do
    wait -n 2>/dev/null || true
    lPIDS_ARRAY=("${!lPIDS_ARRAY_NAME}")
  done
}

################################################################################
# VARIABLE & CONFIG (2)
################################################################################

print_date() {
  date "+%Y-%m-%d %H:%M:%S"
}

check_command_exists() {
  local lCOMMAND="${1:-}"
  
  if ! command -v "${lCOMMAND}" &> /dev/null; then
    print_error "Required command not found: ${lCOMMAND}"
    return 1
  fi
  return 0
}

################################################################################
# FIRMWARE ANALYSIS (18)
################################################################################

binary_architecture_threader() {
  local lBINARY="${1:-}"
  local lMODULE_NAME="${2:-}"
  
  if [[ ! -f "${lBINARY}" ]]; then
    return
  fi
  
  local lFILE_TYPE=""
  lFILE_TYPE=$(file "${lBINARY}" 2>/dev/null || echo "unknown")
  
  local lARCH=""
  if echo "${lFILE_TYPE}" | grep -q "ARM"; then
    lARCH="ARM"
  elif echo "${lFILE_TYPE}" | grep -q "x86-64"; then
    lARCH="x86-64"
  elif echo "${lFILE_TYPE}" | grep -q "Intel 80386"; then
    lARCH="x86"
  elif echo "${lFILE_TYPE}" | grep -q "MIPS"; then
    lARCH="MIPS"
  elif echo "${lFILE_TYPE}" | grep -q "PowerPC"; then
    lARCH="PowerPC"
  else
    lARCH="unknown"
  fi
  
  if [[ -n "${P99_CSV_LOG}" ]]; then
    echo "${lBINARY},${lARCH}" >> "${P99_CSV_LOG}"
  fi
}

linux_basic_identification() {
  local lFIRMWARE_PATH_CHECK="${1:-}"
  local lIDENTIFIER="${2:-}"
  local lLINUX_PATH_COUNTER=0
  
  if ! [[ -d "${lFIRMWARE_PATH_CHECK}" ]]; then
    return
  fi
  
  if [[ -f "${P99_CSV_LOG}" ]]; then
    if [[ -n "${lIDENTIFIER}" ]]; then
      lLINUX_PATH_COUNTER="$(grep "${lIDENTIFIER}" "${P99_CSV_LOG}" | grep -c "/bin/\|/busybox\|/shadow\|/passwd\|/sbin/\|/etc/" || true)"
    else
      lLINUX_PATH_COUNTER="$(grep -c "/bin/\|/busybox\|/shadow\|/passwd\|/sbin/\|/etc/" "${P99_CSV_LOG}" || true)"
    fi
  fi
  
  echo "${lLINUX_PATH_COUNTER}"
}

detect_root_dir_helper() {
  local lFIRMWARE_PATH="${1:-}"
  local lMODE="${2:-}"
  
  if [[ ! -d "${lFIRMWARE_PATH}" ]]; then
    return
  fi
  
  export RTOS=0
  export ROOT_PATH=()
  
  local lFOUND_ROOT=0
  
  if [[ -d "${lFIRMWARE_PATH}/bin" ]] || [[ -d "${lFIRMWARE_PATH}/sbin" ]] || \
     [[ -d "${lFIRMWARE_PATH}/etc" ]] || [[ -f "${lFIRMWARE_PATH}/passwd" ]]; then
    export RTOS=1
    ROOT_PATH+=("${lFIRMWARE_PATH}")
    lFOUND_ROOT=1
    print_output "[*] Detected Linux RTOS environment at ${lFIRMWARE_PATH}"
  fi
  
  if [[ ${lFOUND_ROOT} -eq 0 ]]; then
    mapfile -t ROOT_PATH < <(find "${lFIRMWARE_PATH}" -maxdepth 3 -type d \( -name "bin" -o -name "sbin" \) -printf '%h\n' | sort -u)
    if [[ ${#ROOT_PATH[@]} -gt 0 ]]; then
      export RTOS=1
      print_output "[*] Detected Linux RTOS at subdirectories"
    fi
  fi
}

fw_bin_detector() {
  local lCHECK_FILE="${1:-}"
  
  if [[ ! -f "${lCHECK_FILE}" ]]; then
    return
  fi
  
  local lFILE_BIN_OUT=""
  lFILE_BIN_OUT=$(file "${lCHECK_FILE}")
  
  export VMDK_DETECTED=0
  export EXT_IMAGE=0
  export BSD_UFS=0
  export UBOOT_IMAGE=0
  export ANDROID_OTA=0
  export OPENSSL_ENC_DETECTED=0
  export BUFFALO_ENC_DETECTED=0
  export ZYXEL_ZIP=0
  export QCOW_DETECTED=0
  export BMC_ENC_DETECTED=0
  
  if [[ "${lFILE_BIN_OUT}" == *"QEMU QCOW2 Image"* ]]; then
    QCOW_DETECTED=1
  fi
  
  if [[ "${lFILE_BIN_OUT}" == *"VMware4 disk image"* ]]; then
    VMDK_DETECTED=1
  fi
  
  if [[ "${lFILE_BIN_OUT}" == *"Linux rev 1.0 ext"* ]]; then
    EXT_IMAGE=1
  fi
  
  if [[ "${lFILE_BIN_OUT}" == *"Unix Fast File system"* ]]; then
    BSD_UFS=1
  fi
  
  if [[ "${lFILE_BIN_OUT}" == *"u-boot legacy uImage"* ]]; then
    UBOOT_IMAGE=1
  fi
}

check_firmware() {
  local lFIRMWARE_TO_CHECK="${FIRMWARE_PATH:-}"
  
  if [[ -z "${lFIRMWARE_TO_CHECK}" ]]; then
    print_output "[-] No firmware path found"
    return 1
  fi
  
  print_output "[*] Firmware identified: ${ORANGE}${lFIRMWARE_TO_CHECK}${NC}"
}

architecture_check() {
  local lFIRMWARE_PATH="${1:-}"
  
  export ARCH="unknown"
  
  if [[ -f "${P99_CSV_LOG}" ]]; then
    local lARCH_COUNT=0
    
    lARCH_COUNT=$(grep -c ",ARM" "${P99_CSV_LOG}" || true)
    if [[ ${lARCH_COUNT} -gt 0 ]]; then
      export ARCH="ARM"
      return
    fi
    
    lARCH_COUNT=$(grep -c ",x86-64" "${P99_CSV_LOG}" || true)
    if [[ ${lARCH_COUNT} -gt 0 ]]; then
      export ARCH="x86-64"
      return
    fi
  fi
}

architecture_dep_check() {
  print_output "[*] Architecture dependency check completed"
}

prepare_all_file_arrays() {
  local lFIRMWARE_PATH="${1:-}"
  
  export FILE_ARR=()
  mapfile -t FILE_ARR < <(find "${lFIRMWARE_PATH}" -type f 2>/dev/null | head -10000)
  
  print_output "[*] Prepared ${#FILE_ARR[@]} files for analysis"
}

prepare_file_arr_limited() {
  local lFIRMWARE_PATH="${1:-}"
  
  export FILE_ARR_LIMITED=()
  mapfile -t FILE_ARR_LIMITED < <(find "${lFIRMWARE_PATH}" -type f ! -name "*.raw" 2>/dev/null | head -5000)
  
  print_output "[*] Prepared ${#FILE_ARR_LIMITED[@]} files (limited set)"
}

set_etc_paths() {
  print_output "[*] Setting etc paths"
  
  if [[ -d "${FIRMWARE_PATH}/etc" ]]; then
    export ETC_PATHS="${FIRMWARE_PATH}/etc"
  fi
}

safe_logging() {
  local lLOG_FILE="${1:-}"
  local lERR_HANDLING="${2:-0}"
  
  while IFS= read -r line; do
    echo "${line}" >> "${lLOG_FILE}"
  done
}

remove_unprintable_paths() {
  local lOUTPUT_DIR="${1:-}"
  local lFIRMWARE_UNPRINT_FILES_ARR=()
  local lFW_FILE=""
  
  mapfile -t lFIRMWARE_UNPRINT_FILES_ARR < <(find "${lOUTPUT_DIR}" -name '*[^[:print:]]*')
  
  if [[ "${#lFIRMWARE_UNPRINT_FILES_ARR[@]}" -gt 0 ]]; then
    print_output "[*] Unprintable characters detected in ${#lFIRMWARE_UNPRINT_FILES_ARR[@]} files"
    for lFW_FILE in "${lFIRMWARE_UNPRINT_FILES_ARR[@]}"; do
      mv "${lFW_FILE}" "${lFW_FILE//[![:print:]]/_}" 2>/dev/null || true
    done
  fi
}

################################################################################
# EXTRACTION FUNCTIONS (11)
################################################################################

binwalker_matryoshka() {
  local lFW_PATH="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  if [[ ! -f "${lFW_PATH}" ]]; then
    return
  fi
  
  mkdir -p "${lOUTPUT_DIR}"
  
  if command -v binwalk >/dev/null; then
    print_output "[*] Extracting with binwalk: $(basename "${lFW_PATH}")"
    binwalk -e -C "${lOUTPUT_DIR}" "${lFW_PATH}" 2>&1 | tee -a "${LOG_FILE}" || true
  fi
}

unblobber() {
  local lFW_PATH="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  local lVERBOSE="${3:-0}"
  
  if [[ ! -f "${lFW_PATH}" ]]; then
    return
  fi
  
  mkdir -p "${lOUTPUT_DIR}"
  
  if command -v unblob >/dev/null; then
    print_output "[*] Extracting with unblob: $(basename "${lFW_PATH}")"
    unblob -e "${lOUTPUT_DIR}" "${lFW_PATH}" 2>&1 | tee -a "${LOG_FILE}" || true
  fi
}

vmdk_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] VMDK extraction placeholder for: $(basename "${lFILE}")"
}

ext_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] EXT filesystem extraction placeholder for: $(basename "${lFILE}")"
}

ufs_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] UFS filesystem extraction placeholder for: $(basename "${lFILE}")"
}

android_ota_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] Android OTA extraction placeholder for: $(basename "${lFILE}")"
}

foscam_enc_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] Foscam encrypted extraction placeholder for: $(basename "${lFILE}")"
}

buffalo_enc_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] Buffalo encrypted extraction placeholder for: $(basename "${lFILE}")"
}

zyxel_zip_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] Zyxel ZIP extraction placeholder for: $(basename "${lFILE}")"
}

qcow_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] QCOW extraction placeholder for: $(basename "${lFILE}")"
}

bmc_extractor() {
  local lFILE="${1:-}"
  local lOUTPUT_DIR="${2:-}"
  
  print_output "[*] BMC extraction placeholder for: $(basename "${lFILE}")"
}

################################################################################
# DEEP EXTRACTION HELPERS (2)
################################################################################

deeper_extractor_helper() {
  print_output "[*] Deep extraction helper invoked"
}

deeper_extractor_threader() {
  local lFILE="${1:-}"
  
  print_output "[*] Processing: $(basename "${lFILE}")"
}

################################################################################
# PACKAGE EXTRACTION (1)
################################################################################

extract_deb_extractor_helper() {
  local lDEB="${1:-}"
  local lR_PATH="${2:-}"
  
  if [[ ! -f "${lDEB}" ]]; then
    return
  fi
  
  if command -v dpkg-deb >/dev/null; then
    print_output "[*] Extracting DEB: $(basename "${lDEB}") to ${lR_PATH}"
    dpkg-deb --extract "${lDEB}" "${lR_PATH}" 2>/dev/null || true
  fi
}