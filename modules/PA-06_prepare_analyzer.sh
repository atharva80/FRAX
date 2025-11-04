#!/bin/bash

export PRE_THREAD_ENA=0

PA06_prepare_analyzer() {
  [[ ${THREADED:-0} -eq 1 ]] && wait_for_pid "${WAIT_PIDS[@]}" 2>/dev/null || true

  module_log_init "${FUNCNAME[0]}"

  module_title "Analysis preparation"
  pre_module_reporter "${FUNCNAME[0]}"

  local lNEG_LOG=1

  export LINUX_PATH_COUNTER=0

  if [[ -f "${P99_CSV_LOG}" ]]; then
    LINUX_PATH_COUNTER="$(linux_basic_identification "${LOG_DIR}/firmware")"
  fi

  if [[ ${LINUX_PATH_COUNTER} -gt 0 ]] ; then
    export FIRMWARE=1
    export FIRMWARE_PATH="${LOG_DIR}"/firmware
    backup_var "FIRMWARE_PATH" "${FIRMWARE_PATH}"
  fi

  print_output "[*] Quick check for Linux operating-system"
  check_firmware

  local lFILES_ARR=()
  local lBINARY=""
  local lWAIT_PIDS_PA06_ARR=()

  if [[ ! -f "${P99_CSV_LOG}" ]] || [[ ! -s "${P99_CSV_LOG}" ]]; then
    print_output "[-] INFO: No P99_CSV_LOG log file available"
    if [[ -d "${LOG_DIR}/firmware" ]]; then
      mapfile -t lFILES_ARR < <(find "${LOG_DIR}/firmware" -type f 2>/dev/null | head -100)

      if [[ ${#lFILES_ARR[@]} -gt 0 ]]; then
        print_output "[*] Populating backend data for ${ORANGE}${#lFILES_ARR[@]}${NC} files"

        for lBINARY in "${lFILES_ARR[@]}" ; do
          binary_architecture_threader "${lBINARY}" "${FUNCNAME[0]}" &
          local lTMP_PID="$!"
          store_kill_pids "${lTMP_PID}"
          lWAIT_PIDS_PA06_ARR+=( "${lTMP_PID}" )
        done

        wait_for_pid "${lWAIT_PIDS_PA06_ARR[@]}"
      fi
    fi
  fi

  if [[ -d "${LOG_DIR}/firmware" ]]; then
    detect_root_dir_helper "${LOG_DIR}/firmware" "main"
  fi

  print_ln

  if [[ "${RTOS:-0}" -eq 1 ]] && [[ "${UEFI_VERIFIED:-0}" -eq 1 ]]; then
    print_output "[+] UEFI firmware detected"
  elif [[ "${RTOS:-0}" -eq 1 ]] && [[ "${UEFI_DETECTED:-0}" -eq 1 ]]; then
    print_output "[*] Possible UEFI firmware detected"
  elif [[ "${WINDOWS_EXE:-0}" -eq 1 ]]; then
    print_output "[*] Windows binaries detected"
  elif [[ "${RTOS:-0}" -eq 1 ]]; then
    print_output "[*] Possible RTOS system detected"
  else
    print_output "[-] No known operating system detected"
  fi

  write_log "[*] Analysis preparation completed"

  module_end_log "${FUNCNAME[0]}" "${lNEG_LOG}"
}