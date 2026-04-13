#!/usr/bin/env bash
# build_matrix.sh — build NONMEM Docker images across Ubuntu LTS × NONMEM × gfortran versions
#
# Usage:
#   ./build_matrix.sh [--amd64] [--arm64] [--jobs N]
#
# By default, builds only for the current host architecture.
# Specify one or both architecture flags to override.
#
# Options:
#   --amd64      Build linux/amd64 images
#   --arm64      Build linux/arm64 images (requires docker buildx + QEMU when
#                cross-compiling from an amd64 host; see below)
#   --jobs N     Maximum parallel builds (default: 16)
#
# Prerequisites:
#   1. Copy nonmem_passwords.conf.example to nonmem_passwords.conf and fill in values.
#   2. Place nonmem.lic in NONMEM_ZIP_DIR (set in the conf file).
#
# ARM64 cross-compile prerequisites (one-time setup on an x86-64 host):
#
#   Cross-compiling arm64 images on an amd64 host requires QEMU user-mode
#   emulation and a docker buildx builder that supports multiple platforms.
#
#   1. Install QEMU and binfmt support so the kernel can run arm64 binaries:
#        sudo apt-get install qemu-user-static binfmt-support
#
#   2. Register QEMU binfmt handlers for all foreign architectures:
#        docker run --privileged --rm tonistiigi/binfmt --install all
#      Verify arm64 is listed:
#        ls /proc/sys/fs/binfmt_misc/ | grep qemu
#
#   3. Create a buildx builder that uses the docker-container driver (required
#      for multi-platform support; the default "docker" driver only supports
#      the host architecture):
#        docker buildx create --name multiplatform \
#          --driver docker-container \
#          --driver-opt network=host \
#          --use
#
#   4. Bootstrap the builder (pulls the BuildKit image and starts the container):
#        docker buildx inspect --bootstrap
#      Verify linux/arm64 appears in the Platforms line.
#
#   After this one-time setup, run:
#        ./build_matrix.sh --arm64
#
# Tag format: {NM_VERSION}-ubuntu{UBUNTU}-gfortran{GFC}-{arch}
# Example:    7.5.1-ubuntu24.04-gfortran13-amd64
#
# Results are written to build_matrix.log in the script directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/nonmem_passwords.conf"
LOG_FILE="${SCRIPT_DIR}/build_matrix.log"
MAX_JOBS=16
BUILD_AMD64=false
BUILD_ARM64=false
ARCH_REQUESTED=false

# --- Detect host architecture ---
detect_arch() {
  case "$(uname -m)" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    *)       echo "$(uname -m)" ;;
  esac
}
HOST_ARCH="$(detect_arch)"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --amd64) BUILD_AMD64=true; ARCH_REQUESTED=true; shift ;;
    --arm64) BUILD_ARM64=true; ARCH_REQUESTED=true; shift ;;
    --jobs)  MAX_JOBS="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Default: build only for the current host architecture
if [[ "${ARCH_REQUESTED}" == false ]]; then
  case "${HOST_ARCH}" in
    amd64) BUILD_AMD64=true ;;
    arm64) BUILD_ARM64=true ;;
    *) echo "ERROR: Unknown host architecture '${HOST_ARCH}'. Use --amd64 or --arm64." >&2; exit 1 ;;
  esac
fi

# --- Load config ---
if [[ ! -f "${CONF_FILE}" ]]; then
  echo "ERROR: ${CONF_FILE} not found." >&2
  echo "Copy nonmem_passwords.conf.example to nonmem_passwords.conf and fill in values." >&2
  exit 1
fi
# shellcheck source=/dev/null
source "${CONF_FILE}"

NONMEM_ZIP_DIR="${NONMEM_ZIP_DIR:-/home/bill/tmp/nonmem}"

if [[ ! -f "${NONMEM_ZIP_DIR}/nonmem.lic" ]]; then
  echo "ERROR: nonmem.lic not found in ${NONMEM_ZIP_DIR}" >&2
  exit 1
fi

# --- buildx pre-flight check ---
if ! docker buildx version &>/dev/null; then
  echo "ERROR: docker buildx is not available." >&2
  echo "This script requires docker buildx (included with Docker 20.10+)." >&2
  exit 1
fi

# --- ARM64 pre-flight check (only needed when cross-compiling from amd64) ---
if [[ "${BUILD_ARM64}" == true && "${HOST_ARCH}" != "arm64" ]]; then
  if ! docker buildx inspect 2>/dev/null | grep -q "linux/arm64"; then
    echo "ERROR: linux/arm64 is not available in your current buildx builder." >&2
    echo "Run the ARM64 cross-compile setup steps:" >&2
    echo "  sudo apt-get install qemu-user-static binfmt-support" >&2
    echo "  docker run --privileged --rm tonistiigi/binfmt --install all" >&2
    echo "  docker buildx create --name multiplatform --driver docker-container \\" >&2
    echo "    --driver-opt network=host --use" >&2
    echo "  docker buildx inspect --bootstrap" >&2
    exit 1
  fi
fi

# --- Copy license into build context ---
cp "${NONMEM_ZIP_DIR}/nonmem.lic" "${SCRIPT_DIR}/nonmem.lic"

# --- Initialize log ---
: > "${LOG_FILE}"
echo "Build matrix started at $(date)" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

# --- NONMEM versions: "major minor patch zipfile password" ---
# Zip filenames differ between old (NONMEM7.x.y.zip) and new (NONMEMxyz.zip) conventions.
NONMEM_VERSIONS=(
  "7 2 0 NONMEM7.2.0.zip ${PASS_720}"
  "7 3 0 NONMEM7.3.0.zip ${PASS_730}"
  "7 4 1 NONMEM7.4.1.zip ${PASS_74x}"
  "7 4 2 NONMEM7.4.2.zip ${PASS_74x}"
  "7 4 3 NONMEM7.4.3.zip ${PASS_74x}"
  "7 4 4 NONMEM7.4.4.zip ${PASS_74x}"
  "7 5 0 NONMEM750.zip   ${PASS_75x}"
  "7 5 1 NONMEM751.zip   ${PASS_75x}"
  "7 6 0 NONMEM760.zip   ${PASS_760}"
)

# Ubuntu LTS versions for amd64 builds
AMD64_UBUNTU_VERSIONS=(14.04 16.04 18.04 20.04 22.04 24.04)

# Ubuntu LTS versions for arm64 builds (14.04/16.04 skipped: ARM toolchain too immature)
ARM64_UBUNTU_VERSIONS=(18.04 20.04 22.04 24.04)

# gfortran versions available in standard repos (no PPA) per Ubuntu release.
# Sourced empirically from apt-cache search on each Ubuntu version.
declare -A UBUNTU_GFORTRAN_VERSIONS=(
  ["14.04"]="4.4 4.6 4.7 4.8"
  ["16.04"]="4.7 4.8 4.9 5"
  ["18.04"]="4.8 5 6 7 8"
  ["20.04"]="7 8 9 10"
  ["22.04"]="9 10 11 12"
  ["24.04"]="9 10 11 12 13 14"
)

# For ARM64, only attempt NONMEM 7.5.1+ (older versions have x86-specific setup scripts)
is_compatible_arm64() {
  local major=$1 minor=$2 patch=$3
  if (( major < 7 )) || \
     (( major == 7 && minor < 5 )) || \
     (( major == 7 && minor == 5 && patch == 0 )); then
    return 1
  fi
  return 0
}

# --- Parallel job tracking (by PID) ---
declare -a build_pids=()

run_build() {
  local tag="$1"; shift
  local cmd=("$@")
  {
    if "${cmd[@]}" >/dev/null 2>&1; then
      echo "SUCCESS: ${tag}" | tee -a "${LOG_FILE}"
    else
      echo "FAILED:  ${tag}" | tee -a "${LOG_FILE}"
    fi
  } &
  build_pids+=($!)

  # Throttle: when at the cap, wait for the oldest build to free a slot
  if (( ${#build_pids[@]} >= MAX_JOBS )); then
    wait "${build_pids[0]}" || true
    build_pids=("${build_pids[@]:1}")
  fi
}

# --- amd64 builds ---
if [[ "${BUILD_AMD64}" == true ]]; then
  echo "=== amd64 builds ===" | tee -a "${LOG_FILE}"
  for entry in "${NONMEM_VERSIONS[@]}"; do
    read -r major minor patch zipfile password <<< "${entry}"
    for ubuntu in "${AMD64_UBUNTU_VERSIONS[@]}"; do
      for gfc in ${UBUNTU_GFORTRAN_VERSIONS["${ubuntu}"]}; do
        tag="humanpredictions/nonmem:${major}.${minor}.${patch}-ubuntu${ubuntu}-gfortran${gfc}-amd64"
        run_build "${tag}" \
          docker buildx build \
            --platform linux/amd64 \
            --load \
            --build-context nonmem_zips="${NONMEM_ZIP_DIR}" \
            --build-arg UBUNTU_VERSION="${ubuntu}" \
            --build-arg NONMEM_MAJOR_VERSION="${major}" \
            --build-arg NONMEM_MINOR_VERSION="${minor}" \
            --build-arg NONMEM_PATCH_VERSION="${patch}" \
            --build-arg NONMEM_ZIPFILE="${zipfile}" \
            --build-arg NONMEMZIPPASS="${password}" \
            --build-arg GFORTRAN_VERSION="${gfc}" \
            -t "${tag}" \
            -f "${SCRIPT_DIR}/NONMEM.Dockerfile" \
            "${SCRIPT_DIR}"
      done
    done
  done
fi

# --- arm64 builds ---
if [[ "${BUILD_ARM64}" == true ]]; then
  echo "" | tee -a "${LOG_FILE}"
  echo "=== arm64 builds (Raspberry Pi 4/5 + AWS Graviton2/3/4) ===" | tee -a "${LOG_FILE}"
  for entry in "${NONMEM_VERSIONS[@]}"; do
    read -r major minor patch zipfile password <<< "${entry}"
    if ! is_compatible_arm64 "${major}" "${minor}" "${patch}"; then
      continue
    fi
    for ubuntu in "${ARM64_UBUNTU_VERSIONS[@]}"; do
      for gfc in ${UBUNTU_GFORTRAN_VERSIONS["${ubuntu}"]}; do
        tag="humanpredictions/nonmem:${major}.${minor}.${patch}-ubuntu${ubuntu}-gfortran${gfc}-arm64"
        run_build "${tag}" \
          docker buildx build \
            --platform linux/arm64 \
            --load \
            --build-context nonmem_zips="${NONMEM_ZIP_DIR}" \
            --build-arg UBUNTU_VERSION="${ubuntu}" \
            --build-arg NONMEM_MAJOR_VERSION="${major}" \
            --build-arg NONMEM_MINOR_VERSION="${minor}" \
            --build-arg NONMEM_PATCH_VERSION="${patch}" \
            --build-arg NONMEM_ZIPFILE="${zipfile}" \
            --build-arg NONMEMZIPPASS="${password}" \
            --build-arg GFORTRAN_VERSION="${gfc}" \
            -t "${tag}" \
            -f "${SCRIPT_DIR}/NONMEM.Dockerfile" \
            "${SCRIPT_DIR}"
      done
    done
  done
fi

# --- Wait for all remaining jobs ---
if (( ${#build_pids[@]} > 0 )); then
  wait "${build_pids[@]}" || true
fi

# --- Summary ---
echo "" | tee -a "${LOG_FILE}"
echo "=== Summary ===" | tee -a "${LOG_FILE}"
successes=$(grep -c "^SUCCESS:" "${LOG_FILE}" || true)
failures=$(grep -c "^FAILED:" "${LOG_FILE}" || true)
echo "Succeeded: ${successes}" | tee -a "${LOG_FILE}"
echo "Failed:    ${failures}"  | tee -a "${LOG_FILE}"
echo "Build matrix completed at $(date)" | tee -a "${LOG_FILE}"
