#!/bin/bash

set -euo pipefail

################################################################################
# FRAX Main Entry Script (WITHOUT EXTERNAL CONFIG FILE)
# All variables defined directly in this script
# No frax.conf needed
#
# Usage: ./frax.sh /path/to/firmware.bin
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

################################################################################
# CONFIGURATION - All variables defined here
################################################################################

if [[ -z "${1:-}" ]]; then
  echo "Usage: $0 /path/to/firmware.bin"
  exit 1
fi

export FIRMWARE_PATH="${1}"
export FIRMWARE_PATH_BAK="${FIRMWARE_PATH}"

# Directory structure
export LOG_DIR="${SCRIPT_DIR}/logs"
export LOG_PATH_MODULE="${LOG_DIR}"
export LOG_FILE="${LOG_DIR}/frax_analysis.log"
export BACKUP_FILE="${LOG_DIR}/variables_backup.sh"
export KILL_PIDS_FILE="${LOG_DIR}/.kill_pids"

mkdir -p "${LOG_DIR}"
> "${LOG_FILE}"
> "${KILL_PIDS_FILE}"

# Framework directories
export LIB_DIR="${SCRIPT_DIR}/helpers"
export MODULES_DIR="${SCRIPT_DIR}/modules"
export EXT_DIR="${SCRIPT_DIR}/tools"
export FIRMWARE_DIR="${LOG_DIR}/firmware"

mkdir -p "${FIRMWARE_DIR}"
mkdir -p "${EXT_DIR}"

# Color codes
export ORANGE=$'\033[0;33m'
export RED=$'\033[0;31m'
export GREEN=$'\033[0;32m'
export BLUE=$'\033[0;34m'
export YELLOW=$'\033[1;33m'
export NC=$'\033[0m'

# CSV log files
export P99_CSV_LOG="${LOG_DIR}/p99_architecture.csv"
> "${P99_CSV_LOG}"

# Analysis flags
export SHA512_CHECKSUM="NA"
export SHA1_CHECKSUM="NA"
export MD5_CHECKSUM="NA"
export ENTROPY="NA"

export DLINK_ENC_DETECTED=0
export VMDK_DETECTED=0
export UBOOT_IMAGE=0
export EXT_IMAGE=0
export AVM_DETECTED=0
export BMC_ENC_DETECTED=0
export UBI_IMAGE=0
export OPENSSL_ENC_DETECTED=0
export ENGENIUS_ENC_DETECTED=0
export BUFFALO_ENC_DETECTED=0
export QNAP_ENC_DETECTED=0
export GPG_COMPRESS=0
export BSD_UFS=0
export ANDROID_OTA=0
export UEFI_AMI_CAPSULE=0
export ZYXEL_ZIP=0
export QCOW_DETECTED=0
export UEFI_VERIFIED=0
export DJI_PRAK_DETECTED=0
export DJI_XV4_DETECTED=0
export WINDOWS_EXE=0
export SBOM_MINIMAL=0
export DISABLE_DEEP=0
export UEFI_DETECTED=0
export DJI_DETECTED=0

export RTOS=0
export FULL_EMULATION=0
export KERNEL=0
export THREADED=0

# External tools
export BINWALK_BIN=(/usr/bin/binwalk)

# Verify firmware path
if [[ ! -f "${FIRMWARE_PATH}" ]] && [[ ! -d "${FIRMWARE_PATH}" ]]; then
  echo -e "${RED}[!] ERROR: Firmware path does not exist: ${FIRMWARE_PATH}${NC}"
  exit 1
fi

echo -e "${GREEN}[+] Firmware path: ${FIRMWARE_PATH}${NC}"

################################################################################
# Source helpers and modules
################################################################################

source "${SCRIPT_DIR}/helpers/frax_helpers.sh"

source "${SCRIPT_DIR}/modules/PA-01_firmware_bin_file_check.sh"
source "${SCRIPT_DIR}/modules/PA-02_binwalk_extractor.sh"
source "${SCRIPT_DIR}/modules/PA-03_unblob_extractor.sh"
source "${SCRIPT_DIR}/modules/PA-04_deep_extractor.sh"
source "${SCRIPT_DIR}/modules/PA-05_package_extractor.sh"
source "${SCRIPT_DIR}/modules/PA-06_prepare_analyzer.sh"
source "${SCRIPT_DIR}/modules/PA-Report-Gen.sh"

################################################################################
# Display Banner
################################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                  FRAX - Firmware Analysis Framework            ║"
echo "║              Pre-Analysis & Static Analysis Pipeline           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# Display Configuration
################################################################################

echo "[*] FRAX Configuration:"
echo "    Firmware: ${ORANGE}${FIRMWARE_PATH}${NC}"
echo "    Logs: ${ORANGE}${LOG_DIR}${NC}"
echo "    Log File: ${ORANGE}${LOG_FILE}${NC}"
echo ""

################################################################################
# Execute Pre-Analysis Pipeline
################################################################################

echo "[*] Starting Pre-Analysis Pipeline..."
echo ""

PA01_firmware_bin_file_check
echo ""

PA02_binwalk_extractor
echo ""

PA03_unblob_extractor
echo ""

PA04_deep_extractor
echo ""

PA05_package_extractor
echo ""

PA06_prepare_analyzer
echo ""

################################################################################
# Generate Report
################################################################################

echo "[*] Generating Analysis Report..."
echo ""

PA_Report_Gen

################################################################################
# Completion
################################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║               Analysis Complete & Report Generated            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "[+] Results Summary:"
echo "    Main Log: ${ORANGE}${LOG_FILE}${NC}"
echo "    CSV Data: ${ORANGE}${P99_CSV_LOG}${NC}"
echo "    Report: ${ORANGE}${LOG_DIR}/FRAX_ANALYSIS_REPORT.txt${NC}"
echo ""

if [[ -f "${LOG_DIR}/FRAX_ANALYSIS_REPORT.txt" ]]; then
  echo "[+] Report successfully generated!"
  echo ""
  echo "View report with:"
  echo "    cat ${LOG_DIR}/FRAX_ANALYSIS_REPORT.txt"
else
  echo "[!] Report generation may have failed"
fi

echo ""
echo "Analysis directory: ${LOG_DIR}"
echo ""