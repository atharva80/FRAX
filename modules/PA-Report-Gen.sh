#!/bin/bash

export PRE_THREAD_ENA=0

PA_Report_Gen() {
  module_log_init "${FUNCNAME[0]}"

  module_title "Analysis Report Generation"
  pre_module_reporter "${FUNCNAME[0]}"

  local lREPORT_FILE="${LOG_DIR}/FRAX_ANALYSIS_REPORT.txt"
  local lREPORT_CSV="${LOG_DIR}/FRAX_ANALYSIS_REPORT.csv"

  print_output "[*] Generating analysis report..."

  generate_text_report "${lREPORT_FILE}"
  generate_csv_report "${lREPORT_CSV}"

  if [[ -f "${lREPORT_FILE}" ]]; then
    print_output "[+] Text report generated: ${ORANGE}${lREPORT_FILE}${NC}"
    write_csv_log "Report Generation" "Text Report" "Success"
  else
    print_output "[-] Text report generation failed"
    write_csv_log "Report Generation" "Text Report" "Failed"
  fi

  if [[ -f "${lREPORT_CSV}" ]]; then
    print_output "[+] CSV report generated: ${ORANGE}${lREPORT_CSV}${NC}"
    write_csv_log "Report Generation" "CSV Report" "Success"
  else
    print_output "[-] CSV report generation failed"
    write_csv_log "Report Generation" "CSV Report" "Failed"
  fi

  module_end_log "${FUNCNAME[0]}" 1
}

generate_text_report() {
  local lREPORT_FILE="${1:-}"

  if [[ -z "${lREPORT_FILE}" ]]; then
    return
  fi

  print_output "[*] Creating text report: $(basename "${lREPORT_FILE}")"

  {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         FRAX FIRMWARE ANALYSIS REPORT                         ║"
    echo "║     Pre-Analysis & Static Analysis Results                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    echo "ANALYSIS METADATA"
    echo "═══════════════════════════════════════════════════════════════"
    echo "Firmware Path: ${FIRMWARE_PATH}"
    echo "Analysis Date: $(print_date)"
    echo "Log Directory: ${LOG_DIR}"
    echo ""

    echo "FIRMWARE INFORMATION"
    echo "═══════════════════════════════════════════════════════════════"
    if [[ -n "${MD5_CHECKSUM:-}" ]] && [[ "${MD5_CHECKSUM}" != "NA" ]]; then
      echo "MD5 Hash: ${MD5_CHECKSUM}"
    fi
    if [[ -n "${SHA1_CHECKSUM:-}" ]] && [[ "${SHA1_CHECKSUM}" != "NA" ]]; then
      echo "SHA1 Hash: ${SHA1_CHECKSUM}"
    fi
    if [[ -n "${SHA512_CHECKSUM:-}" ]] && [[ "${SHA512_CHECKSUM}" != "NA" ]]; then
      echo "SHA512 Hash: ${SHA512_CHECKSUM}"
    fi
    if [[ -n "${ENTROPY:-}" ]] && [[ "${ENTROPY}" != "NA" ]]; then
      echo "Entropy: ${ENTROPY} bits per byte"
    fi
    echo ""

    echo "FIRMWARE TYPE DETECTION"
    echo "═══════════════════════════════════════════════════════════════"
    local lFW_DETECTED=0
    if [[ ${AVM_DETECTED:-0} -eq 1 ]]; then
      echo "[+] AVM Firmware Detected"
      lFW_DETECTED=1
    fi
    if [[ ${DJI_PRAK_DETECTED:-0} -eq 1 ]]; then
      echo "[+] DJI PRAK Firmware Detected"
      lFW_DETECTED=1
    fi
    if [[ ${DJI_XV4_DETECTED:-0} -eq 1 ]]; then
      echo "[+] DJI XV4 Firmware Detected"
      lFW_DETECTED=1
    fi
    if [[ ${UEFI_DETECTED:-0} -eq 1 ]]; then
      echo "[+] UEFI Firmware Detected"
      lFW_DETECTED=1
    fi
    if [[ ${UEFI_VERIFIED:-0} -eq 1 ]]; then
      echo "[+] UEFI Firmware Verified"
      lFW_DETECTED=1
    fi
    if [[ ${WINDOWS_EXE:-0} -eq 1 ]]; then
      echo "[+] Windows Executable Detected"
      lFW_DETECTED=1
    fi
    if [[ ${lFW_DETECTED} -eq 0 ]]; then
      echo "[-] No specific firmware type detected"
    fi
    echo ""

    echo "ENCRYPTION & COMPRESSION DETECTION"
    echo "═══════════════════════════════════════════════════════════════"
    local lENC_DETECTED=0
    if [[ ${DLINK_ENC_DETECTED:-0} -gt 0 ]]; then
      echo "[+] D-Link Encryption Detected (Type: ${DLINK_ENC_DETECTED})"
      lENC_DETECTED=1
    fi
    if [[ ${OPENSSL_ENC_DETECTED:-0} -eq 1 ]]; then
      echo "[+] OpenSSL Encryption Detected"
      lENC_DETECTED=1
    fi
    if [[ ${ENGENIUS_ENC_DETECTED:-0} -eq 1 ]]; then
      echo "[+] EnGenius Encryption Detected"
      lENC_DETECTED=1
    fi
    if [[ ${BUFFALO_ENC_DETECTED:-0} -eq 1 ]]; then
      echo "[+] Buffalo Encryption Detected"
      lENC_DETECTED=1
    fi
    if [[ ${QNAP_ENC_DETECTED:-0} -eq 1 ]]; then
      echo "[+] QNAP Encryption Detected"
      lENC_DETECTED=1
    fi
    if [[ ${BMC_ENC_DETECTED:-0} -eq 1 ]]; then
      echo "[+] BMC Encryption Detected"
      lENC_DETECTED=1
    fi
    if [[ ${GPG_COMPRESS:-0} -eq 1 ]]; then
      echo "[+] GPG Compression Detected"
      lENC_DETECTED=1
    fi
    if [[ ${lENC_DETECTED} -eq 0 ]]; then
      echo "[-] No encryption or compression detected"
    fi
    echo ""

    echo "ARCHIVE & FILESYSTEM DETECTION"
    echo "═══════════════════════════════════════════════════════════════"
    local lARCH_DETECTED=0
    if [[ ${UBI_IMAGE:-0} -eq 1 ]]; then
      echo "[+] UBI Filesystem Detected"
      lARCH_DETECTED=1
    fi
    if [[ ${EXT_IMAGE:-0} -eq 1 ]]; then
      echo "[+] EXT Filesystem Detected"
      lARCH_DETECTED=1
    fi
    if [[ ${BSD_UFS:-0} -eq 1 ]]; then
      echo "[+] BSD UFS Filesystem Detected"
      lARCH_DETECTED=1
    fi
    if [[ ${UBOOT_IMAGE:-0} -eq 1 ]]; then
      echo "[+] U-Boot Image Detected"
      lARCH_DETECTED=1
    fi
    if [[ ${VMDK_DETECTED:-0} -eq 1 ]]; then
      echo "[+] VMDK Image Detected"
      lARCH_DETECTED=1
    fi
    if [[ ${QCOW_DETECTED:-0} -eq 1 ]]; then
      echo "[+] QCOW Image Detected"
      lARCH_DETECTED=1
    fi
    if [[ ${ZYXEL_ZIP:-0} -eq 1 ]]; then
      echo "[+] Zyxel ZIP Detected"
      lARCH_DETECTED=1
    fi
    if [[ ${ANDROID_OTA:-0} -eq 1 ]]; then
      echo "[+] Android OTA Detected"
      lARCH_DETECTED=1
    fi
    if [[ ${lARCH_DETECTED} -eq 0 ]]; then
      echo "[-] No specific archive/filesystem detected"
    fi
    echo ""

    echo "OPERATING SYSTEM DETECTION"
    echo "═══════════════════════════════════════════════════════════════"
    if [[ ${RTOS:-0} -eq 1 ]]; then
      echo "[+] Linux RTOS Detected"
    else
      echo "[-] No Linux RTOS Detected"
    fi

    if [[ -n "${ARCH:-}" ]] && [[ "${ARCH}" != "unknown" ]]; then
      echo "[+] Architecture: ${ARCH}"
    fi

    if [[ -n "${LINUX_PATH_COUNTER:-}" ]]; then
      echo "[+] Linux Path Counter: ${LINUX_PATH_COUNTER}"
    fi
    echo ""

    echo "EXTRACTION SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    if [[ -f "${P99_CSV_LOG}" ]]; then
      local lFILE_COUNT=$(wc -l < "${P99_CSV_LOG}" || echo "0")
      echo "[+] Total Files Identified: ${lFILE_COUNT}"
    fi

    if [[ -d "${LOG_DIR}/firmware" ]]; then
      local lEXTRACTED_COUNT=$(find "${LOG_DIR}/firmware" -type f 2>/dev/null | wc -l || echo "0")
      echo "[+] Total Files Extracted: ${lEXTRACTED_COUNT}"
    fi
    echo ""

    echo "ANALYSIS LOGS"
    echo "═══════════════════════════════════════════════════════════════"
    echo "Main Log: ${LOG_FILE}"
    echo "CSV Log: ${P99_CSV_LOG}"
    echo "Firmware Dir: ${LOG_DIR}/firmware"
    echo ""

    echo "═══════════════════════════════════════════════════════════════"
    echo "Report Generated: $(print_date)"
    echo "═══════════════════════════════════════════════════════════════"

  } > "${lREPORT_FILE}"

  print_output "[+] Text report saved successfully"
}

generate_csv_report() {
  local lREPORT_CSV="${1:-}"

  if [[ -z "${lREPORT_CSV}" ]]; then
    return
  fi

  print_output "[*] Creating CSV report: $(basename "${lREPORT_CSV}")"

  {
    echo "Category,Item,Value,Status"
    echo "Metadata,Firmware Path,${FIRMWARE_PATH},Found"
    echo "Metadata,Analysis Date,$(print_date),Complete"
    echo ""

    if [[ -n "${SHA512_CHECKSUM:-}" ]] && [[ "${SHA512_CHECKSUM}" != "NA" ]]; then
      echo "Hash,SHA512,${SHA512_CHECKSUM},Calculated"
    fi
    if [[ -n "${SHA1_CHECKSUM:-}" ]] && [[ "${SHA1_CHECKSUM}" != "NA" ]]; then
      echo "Hash,SHA1,${SHA1_CHECKSUM},Calculated"
    fi
    if [[ -n "${MD5_CHECKSUM:-}" ]] && [[ "${MD5_CHECKSUM}" != "NA" ]]; then
      echo "Hash,MD5,${MD5_CHECKSUM},Calculated"
    fi
    if [[ -n "${ENTROPY:-}" ]] && [[ "${ENTROPY}" != "NA" ]]; then
      echo "Analysis,Entropy,${ENTROPY},Measured"
    fi
    echo ""

    if [[ ${AVM_DETECTED:-0} -eq 1 ]]; then
      echo "Detection,AVM Firmware,Detected,Confirmed"
    fi
    if [[ ${UEFI_DETECTED:-0} -eq 1 ]]; then
      echo "Detection,UEFI Firmware,Detected,Confirmed"
    fi
    if [[ ${WINDOWS_EXE:-0} -eq 1 ]]; then
      echo "Detection,Windows Executable,Detected,Confirmed"
    fi
    echo ""

    if [[ ${RTOS:-0} -eq 1 ]]; then
      echo "OS,Linux RTOS,Detected,Confirmed"
    fi
    if [[ -n "${ARCH:-}" ]]; then
      echo "OS,Architecture,${ARCH},Detected"
    fi

  } > "${lREPORT_CSV}"

  print_output "[+] CSV report saved successfully"
}