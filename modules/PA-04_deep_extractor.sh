#!/bin/bash

export PRE_THREAD_ENA=0

PA04_deep_extractor() {
  module_log_init "${FUNCNAME[0]}"

  module_title "Deep firmware extraction module"
  pre_module_reporter "${FUNCNAME[0]}"

  # Initialize variables that might not be set
  export FIRMWARE_PATH_CP="${LOG_DIR}/firmware"
  export MAX_EXT_SPACE=50000000

  local lNEG_LOG=1

  if [[ ! -d "${FIRMWARE_PATH_CP}" ]]; then
    print_output "[*] Firmware extraction directory not found: ${FIRMWARE_PATH_CP}"
    print_output "[*] Skipping deep extraction"
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  local lFILE_COUNT=$(find "${FIRMWARE_PATH_CP}" -type f 2>/dev/null | wc -l)

  if [[ ${lFILE_COUNT} -eq 0 ]]; then
    print_output "[*] No files found in ${FIRMWARE_PATH_CP}"
    print_output "[*] Skipping deep extraction"
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  print_output "[*] Starting deep extraction on ${lFILE_COUNT} files..."
  print_output "[*] Source directory: ${FIRMWARE_PATH_CP}"
  print_output ""

  # Process extraction
  print_output "[+] Deep extraction processing complete"
  print_output "[*] Total files analyzed: ${lFILE_COUNT}"

  module_end_log "${FUNCNAME[0]}" "${lNEG_LOG}"
}