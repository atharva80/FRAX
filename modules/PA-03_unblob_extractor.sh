#!/bin/bash

export PRE_THREAD_ENA=0

PA03_unblob_extractor() {
  module_log_init "${FUNCNAME[0]}"

  module_title "Unblob firmware extractor"
  pre_module_reporter "${FUNCNAME[0]}"

  if [[ -z "${FIRMWARE_PATH}" ]]; then
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  local lOUTPUT_DIR="${LOG_DIR}/firmware"
  mkdir -p "${lOUTPUT_DIR}"

  print_output "[*] Extracting firmware with unblob..."
  print_output "[*] Source: ${ORANGE}${FIRMWARE_PATH}${NC}"
  print_output "[*] Output: ${ORANGE}${lOUTPUT_DIR}${NC}"

  if command -v unblob &> /dev/null; then
    # Use correct unblob syntax: unblob -e output_dir firmware.bin
    unblob -e "${lOUTPUT_DIR}" "${FIRMWARE_PATH}" 2>&1 | tee -a "${LOG_FILE}" || true

    # Check if extraction actually happened
    local lFILE_COUNT=$(find "${lOUTPUT_DIR}" -type f 2>/dev/null | wc -l)

    if [[ ${lFILE_COUNT} -gt 0 ]]; then
      print_output "[+] Unblob extraction successful!"
      print_output "[+] Extracted ${ORANGE}${lFILE_COUNT}${NC} files"

      # Run root directory detection on extracted files
      detect_root_dir_helper "${lOUTPUT_DIR}"

      write_csv_log "UNBLOB" "EXTRACTION" "SUCCESS"
      write_csv_log "UNBLOB" "FILES_COUNT" "${lFILE_COUNT}"
    else
      print_output "[-] Unblob extraction produced no files"
      write_csv_log "UNBLOB" "EXTRACTION" "NO_FILES"
    fi
  else
    print_output "[-] unblob not found - skipping unblob extraction"
    write_csv_log "UNBLOB" "EXTRACTION" "TOOL_NOT_FOUND"
  fi

  module_end_log "${FUNCNAME[0]}" 0
}