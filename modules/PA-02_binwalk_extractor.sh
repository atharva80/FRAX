#!/bin/bash

export PRE_THREAD_ENA=0

PA02_binwalk_extractor() {
  module_log_init "${FUNCNAME[0]}"

  module_title "Binwalk firmware extractor"
  pre_module_reporter "${FUNCNAME[0]}"

  if [[ -z "${FIRMWARE_PATH}" ]]; then
    module_end_log "${FUNCNAME[0]}" 0
    return
  fi

  # Create module-specific output directory
  local lOUTPUT_DIR="${LOG_DIR}/PA02_binwalk_extractor"
  mkdir -p "${lOUTPUT_DIR}"

  print_output "[*] Extracting firmware with binwalk..."
  print_output "[*] Source: ${ORANGE}${FIRMWARE_PATH}${NC}"
  print_output "[*] Output: ${ORANGE}${lOUTPUT_DIR}${NC}"

  if command -v binwalk &> /dev/null; then
    # Use correct binwalk syntax with --directory flag
    binwalk -e --directory="${lOUTPUT_DIR}" "${FIRMWARE_PATH}" 2>&1 | tee -a "${LOG_FILE}" || true

    # Binwalk creates _firmware.bin.extracted/ subdirectory
    local lEXTRACTED_DIR=$(find "${lOUTPUT_DIR}" -maxdepth 1 -type d -name "*extracted*" 2>/dev/null | head -1)

    if [[ -n "${lEXTRACTED_DIR}" ]]; then
      # Count files in extracted directory
      local lFILE_COUNT=$(find "${lEXTRACTED_DIR}" -type f 2>/dev/null | wc -l)

      if [[ ${lFILE_COUNT} -gt 0 ]]; then
        print_output "[+] Binwalk extraction successful!"
        print_output "[+] Extracted directory: ${ORANGE}${lEXTRACTED_DIR}${NC}"
        print_output "[+] File count: ${ORANGE}${lFILE_COUNT}${NC} files"

        # Copy extracted files to common firmware directory for other modules
        print_output "[*] Copying extracted files to common location..."
        local lFIRMWARE_DIR="${LOG_DIR}/firmware"
        mkdir -p "${lFIRMWARE_DIR}"
        cp -r "${lEXTRACTED_DIR}"/* "${lFIRMWARE_DIR}/" 2>/dev/null || true

        # Run root directory detection
        detect_root_dir_helper "${lFIRMWARE_DIR}"

        write_csv_log "BINWALK" "EXTRACTION" "SUCCESS"
        write_csv_log "BINWALK" "FILES_COUNT" "${lFILE_COUNT}"
        write_csv_log "BINWALK" "EXTRACTED_DIR" "${lEXTRACTED_DIR}"
      else
        print_output "[-] Extracted directory found but no files inside"
        write_csv_log "BINWALK" "EXTRACTION" "NO_FILES"
      fi
    else
      print_output "[-] No extracted directory found"
      print_output "[*] Check: ls -la ${lOUTPUT_DIR}/"
      write_csv_log "BINWALK" "EXTRACTION" "NO_EXTRACTED_DIR"
    fi
  else
    print_output "[-] binwalk not found - skipping binwalk extraction"
    write_csv_log "BINWALK" "EXTRACTION" "TOOL_NOT_FOUND"
  fi

  module_end_log "${FUNCNAME[0]}" 0
}