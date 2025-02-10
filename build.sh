#!/usr/bin/env bash
set -e

function usage() {
  cat <<EOM
Marlin Firmware Builder
(rev. $(git rev-parse --short HEAD))

Easily build your Marlin firmware.

Usage : ./build.sh --cfg-subfolder <path-to-marlin-config-headers> --platform <platform> [--src-ref <marlin-source-ref>] [--cfg-ref <marlin-cfg-ref>] [--output <output-filename>]

Example : ./build.sh -c "config/examples/Creality/Ender-5 Pro/CrealityV422" -p "STM32F103RC_creality" -s "2.1.2"

Arguments :

[Mandatory]
-c|--cfg-subfolder : Marlin configuration subfolder, where 'configuration.h' file is found, relative to Marlin configuration repository's root (e.g. 'config/examples/Creality/Ender-5 Pro/CrealityV422')

-p|--platform : Platform to be used by platformio to perform the build (e.g. 'STM32F103RC_creality')

[Optional]
-s|--src-ref : Marlin firmware source revision, can be a commit, a tag, a branch (defaults to '2.1.2.5')

-C|--cfg-ref : Marlin firmware configuration revision, can be a commit, a tag, a branch (defaults to Marlin's source revision)

-o|--output : Output filename (defaults to "Marlin-<marlin-source-ref>-<platform>_<date>.bin")
EOM
}

while [[ $# -gt 0 ]]; do
  case $1 in
  -s | --src-ref)
    MARLIN_SRC_REF="$2"
    shift
    shift
    ;;
  -C | --cfg-ref)
    MARLIN_CFG_REF="$2"
    shift
    shift
    ;;
  -c | --cfg-subfolder)
    MARLIN_CFG_SUBFOLDER="$2"
    shift
    shift
    ;;
  -p | --platform)
    PLATFORM="$2"
    shift
    shift
    ;;
  -o | --output)
    FIRMWARE_NAME="$2"
    shift
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  --* | -*)
    usage
    exit 1
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done

## Variables, tweak these as you like or provide values at runtime ##

# Default Marlin source code ref to fetch
[[ -z ${MARLIN_SRC_REF} ]] && MARLIN_SRC_REF="2.1.2.5"

# Default Marlin configuration ref to fetch
[[ -z ${MARLIN_CFG_REF} ]] && MARLIN_CFG_REF=${MARLIN_SRC_REF}

# Default Artifact name, this will be a tar.xz archive containing the .bin firmware to flash as well as the configuration used and build info.
[[ -z ${FIRMWARE_NAME} ]] && FIRMWARE_NAME="Marlin-${MARLIN_SRC_REF}-${PLATFORM}_$(date +'%Y%m%d%H%M%S')"

# Marlin source repo, you probably don't need to change this
MARLIN_SRC_REPO=https://github.com/MarlinFirmware/Marlin.git

# Marlin Configurations source repo, you probably don't need to change this
MARLIN_CFG_REPO=https://github.com/MarlinFirmware/Configurations.git

#########################################
## NO NEED TO MODIFY BEYOND THIS POINT ##
#########################################

# Checks #

command -v git >/dev/null 2>&1 || {
  printf "\n\033[0;31mYou need git\033[0m\n"
  exit 1
}
command -v docker >/dev/null 2>&1 || {
  printf "\n\033[0;31mYou need docker\033[0m\n"
  exit 1
}
[[ -z ${MARLIN_SRC_REPO} ]] && {
  printf "\n\033[0;31mYou need to set MARLIN_SRC_REPO variable\033[0m\n"
  exit 1
}
[[ -z ${MARLIN_CFG_REPO} ]] && {
  printf "\n\033[0;31mYou need to set MARLIN_CFG_REPO variable\033[0m\n"
  exit 1
}
[[ -z ${MARLIN_SRC_REF} ]] && {
  printf "\n\033[0;31mYou need to set MARLIN_SRC_REF variable\033[0m\n"
  exit 1
}
[[ -z ${MARLIN_CFG_REF} ]] && MARLIN_CFG_REF=${MARLIN_SRC_REF}
[[ -z ${MARLIN_CFG_SUBFOLDER} ]] && {
  usage
  exit 1
}
[[ -z ${PLATFORM} ]] && {
  usage
  exit 1
}
[[ -z ${FIRMWARE_NAME} ]] && {
  printf "\n\033[0;31mYou need to set FIRMWARE_NAME variable\033[0m\n"
  exit 1
}

WORKING_DIR="$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd -P
)"

# Fetch missing source code #

printf "\n\033[0;32mGetting Marlin source code for branch %s\033[0m\n" "${MARLIN_SRC_REF}"

TMP_SRC="${WORKING_DIR}/source/firmware/${MARLIN_SRC_REF}"
[[ -d ${TMP_SRC} ]] || mkdir -p "${TMP_SRC}"

if [[ ! $(git -C "${TMP_SRC}" remote -v | grep origin | grep fetch | awk '{print $2}') == "${MARLIN_SRC_REPO}" || $(git -C "${TMP_SRC}" rev-parse HEAD) != $(git -C "${TMP_SRC}" rev-parse "${MARLIN_SRC_REF}") ]]; then
  echo "Cloning Marlin from GitHub to ${TMP_SRC}"
  git clone --depth=1 --single-branch --branch "${MARLIN_SRC_REF}" "${MARLIN_SRC_REPO}" "${TMP_SRC}" || {
    printf "\n\033[0;31mFailed to clone Marlin\033[0m\n"
    exit 1
  }
else
  echo "Using cached Marlin at ${TMP_SRC}"
  git -C "${TMP_SRC}" reset --hard HEAD
fi

printf "\n\033[0;32mGetting Marlin Configurations for branch %s\033[0m\n" "${MARLIN_SRC_REF}"

mkdir -p "${WORKING_DIR}/config"
TMP_CFG="${WORKING_DIR}/source/configurations/${MARLIN_CFG_REF}"
[[ -d ${TMP_CFG} ]] || mkdir -p "${TMP_CFG}"

if [[ ! $(git -C "${TMP_CFG}" remote -v | grep origin | grep fetch | awk '{print $2}') == "${MARLIN_CFG_REPO}" || $(git -C "${TMP_CFG}" rev-parse HEAD) != $(git -C "${TMP_CFG}" rev-parse "${MARLIN_CFG_REF}") ]]; then
  echo "Cloning Marlin Configurations from GitHub to ${TMP_CFG}"
  git clone --depth=1 --single-branch --branch "${MARLIN_CFG_REF}" "${MARLIN_CFG_REPO}" "${TMP_CFG}" || {
    printf "\n\033[0;31mFailed to clone Configurations\033[0m\n"
    exit 1
  }
  cp --remove-destination --verbose "${TMP_CFG}/${MARLIN_CFG_SUBFOLDER}"/*.h "${WORKING_DIR}"/config/
  printf "\n\033[0;32m => Configuration initialized. Edit config/*.h and run the script again. <=\033[0m\n"
  exit 0
else
  echo "Using cached Configurations at ${TMP_CFG}"
  cp --update --verbose "${TMP_CFG}/${MARLIN_CFG_SUBFOLDER}"/*.h "${WORKING_DIR}"/config/
fi

# Configure #
printf "\n\033[0;32mInjecting Configuration\033[0m\n"

cp --remove-destination --verbose config/*.h "${TMP_SRC}"/Marlin/
tmp_venv=".venv-$(mktemp -u XXXXX)"
python -m venv "${tmp_venv}"
# shellcheck source=/dev/null
source "./${tmp_venv}/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt
pio upgrade --dev
cd "${TMP_SRC}"
buildroot/bin/format_code

# Build #
printf "\n\033[0;32mCompiling Marlin for %s\033[0m\n" "${PLATFORM}"

pio run --target clean -e "${PLATFORM}"
pio run -e "${PLATFORM}" --silent

# Pack #
printf "\n\033[0;32mCopying compiled firmware\033[0m\n"

find "${TMP_SRC}/.pio/build/${PLATFORM}" -name "firmware-*.bin" -exec cp --remove-destination --verbose '{}' "${WORKING_DIR}/${FIRMWARE_NAME}.bin" \;
if [[ ! -e "${WORKING_DIR}/${FIRMWARE_NAME}.bin" ]]; then
  printf "\n\033[0;31m => Firmware compilation failed, check logs <=\033[0m\n\n"
  exit 1
fi

{
  echo "MARLIN_SRC_REPO=${MARLIN_SRC_REPO}"
  echo "MARLIN_SRC_REF=${MARLIN_SRC_REF}"
  echo "MARLIN_CFG_REPO=${MARLIN_CFG_REPO}"
  echo "MARLIN_CFG_REF=${MARLIN_CFG_REF}"
  echo "MARLIN_CFG_SUBFOLDER=${MARLIN_CFG_SUBFOLDER}"
} >"${WORKING_DIR}/build-info.txt"

cd "${WORKING_DIR}"
tar cvJf "${FIRMWARE_NAME}.tar.xz" build-info.txt "${FIRMWARE_NAME}.bin" config/*.h

printf "\n\033[0;32mFirmware successfully compiled\033[0m\n"

# Cleanup #
deactivate
rm -rf "${tmp_venv}"
rm -f "${WORKING_DIR}/${FIRMWARE_NAME}.bin" "${WORKING_DIR}/build-info.txt"

printf '\n\033[0;32m => %s.tar.xz <=\033[0m\n\n' "${FIRMWARE_NAME}"
