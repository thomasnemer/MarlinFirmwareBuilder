#!/usr/bin/env bash
set -e

## Variables, tweak these as you like ##

# Marlin source code ref to fetch
MARLIN_SRC_REF="bugfix-2.1.x"

# Marlin configuration ref to fetch
# MARLIN_SRC_REF value will be used if empty
MARLIN_CFG_REF=""

# Marlin docker-compose.yml file ref to fetch
# MARLIN_SRC_REF value will be used if empty
MARLIN_DOCKER_BUILDER_REF="2.1.2"

# Marlin configuration subfolder to use when fetching configurations
MARLIN_CFG_SUBFOLDER="config/examples/Creality/Ender-5 Pro/CrealityV422"

# Platform to use for firmware building
PLATFORM="STM32F103RC_creality"

# Artefact name, this is the file you will flash on your printer
FIRMWARE_NAME="Marlin-${MARLIN_SRC_REF}-${PLATFORM}-Ender5Pro-v422-BLTouch.bin"

# Marlin source repo, you probably don't need to change this
MARLIN_SRC_REPO=https://github.com/MarlinFirmware/Marlin.git

# Marlin Configurations source repo, you probably don't need to change this
MARLIN_CFG_REPO=https://github.com/MarlinFirmware/Configurations.git

#########################################
## NO NEED TO MODIFY BEYOND THIS POINT ##
#########################################

# Checks #

command -v git >/dev/null 2>&1 || { printf "\n\033[0;31mYou need git\033[0m\n"; exit 1; }
command -v docker >/dev/null 2>&1 || { printf "\n\033[0;31mYou need docker\033[0m\n"; exit 1; }
docker compose version >/dev/null 2>&1 || { printf "\n\033[0;31mYou need docker compose plugin\033[0m\n"; exit 1; }
[[ -z ${MARLIN_SRC_REPO} ]] && { printf "\n\033[0;31mYou need to set MARLIN_SRC_REPO variable\033[0m\n"; exit 1; }
[[ -z ${MARLIN_CFG_REPO} ]] && { printf "\n\033[0;31mYou need to set MARLIN_CFG_REPO variable\033[0m\n"; exit 1; }
[[ -z ${MARLIN_SRC_REF} ]] && { printf "\n\033[0;31mYou need to set MARLIN_SRC_REF variable\033[0m\n"; exit 1; }
[[ -z ${MARLIN_CFG_REF} ]] && MARLIN_CFG_REF=${MARLIN_SRC_REF}
[[ -z ${MARLIN_DOCKER_BUILDER_REF} ]] && MARLIN_DOCKER_BUILDER_REF=${MARLIN_SRC_REF}
[[ -z ${MARLIN_CFG_SUBFOLDER} ]] && { printf "\n\033[0;31mYou need to set MARLIN_CFG_SUBFOLDER variable\033[0m\n"; exit 1; }
[[ -z ${PLATFORM} ]] && { printf "\n\033[0;31mYou need to set PLATFORM variable\033[0m\n"; exit 1; }
[[ -z ${FIRMWARE_NAME} ]] && { printf "\n\033[0;31mYou need to set FIRMWARE_NAME variable\033[0m\n"; exit 1; }

WORKING_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"

# Fetch missing source code #

printf "\n\033[0;32mGetting Marlin source code for branch %s\033[0m\n" ${MARLIN_SRC_REF}

TMP_SRC="${WORKING_DIR}/source/firmware/${MARLIN_SRC_REF}"
[[ -d "${TMP_SRC}" ]] || mkdir -p "${TMP_SRC}"

if [[ ! "$(git -C ${TMP_SRC} remote -v | grep origin | grep fetch | awk '{print $2}')" == "${MARLIN_SRC_REPO}" || "$(git -C ${TMP_SRC} rev-parse HEAD)" != "$(git -C ${TMP_SRC} rev-parse ${MARLIN_SRC_REF})" ]]; then
  echo "Cloning Marlin from GitHub to ${TMP_SRC}"
  git clone --depth=1 --single-branch --branch "${MARLIN_SRC_REF}" ${MARLIN_SRC_REPO} "${TMP_SRC}" || { printf "\n\033[0;31mFailed to clone Marlin\033[0m\n"; exit 1; }
else
  echo "Using cached Marlin at ${TMP_SRC}"
  git -C ${TMP_SRC} reset --hard HEAD
fi

printf "\n\033[0;32mGetting Marlin Configurations for branch %s\033[0m\n" ${MARLIN_SRC_REF}

TMP_CFG="${WORKING_DIR}/source/configurations/${MARLIN_CFG_REF}"
[[ -d "${TMP_CFG}" ]] || mkdir -p "${TMP_CFG}"

if [[ ! $(git -C ${TMP_CFG} remote -v | grep origin | grep fetch | awk '{print $2}') == "${MARLIN_CFG_REPO}" || "$(git -C ${TMP_CFG} rev-parse HEAD)" != "$(git -C ${TMP_CFG} rev-parse ${MARLIN_CFG_REF})" ]]; then
  echo "Cloning Marlin Configurations from GitHub to ${TMP_CFG}"
  git clone --depth=1 --single-branch --branch "${MARLIN_CFG_REF}" ${MARLIN_CFG_REPO} "${TMP_CFG}" || { printf "\n\033[0;31mFailed to clone Configurations\033[0m\n"; exit 1; }
  cp --remove-destination --verbose "${TMP_CFG}/${MARLIN_CFG_SUBFOLDER}"/*.h ${WORKING_DIR}/config/
  printf "\n\033[0;32m => Configuration initialized. Edit config/*.h and run the script again. <=\033[0m\n"
  exit 0
else
  echo "Using cached Configurations at ${TMP_CFG}"
    cp --update --verbose "${TMP_CFG}/${MARLIN_CFG_SUBFOLDER}"/*.h ${WORKING_DIR}/config/
fi

printf "\n\033[0;32mGetting Marlin docker builder source code for branch %s\033[0m\n" ${MARLIN_DOCKER_BUILDER_REF}

TMP_DCK="${WORKING_DIR}/source/docker/${MARLIN_DOCKER_BUILDER_REF}"
[[ -d "${TMP_DCK}" ]] || mkdir -p "${TMP_DCK}"

if [[ ! $(git -C ${TMP_DCK} remote -v | grep origin | grep fetch | awk '{print $2}') == "${MARLIN_SRC_REPO}" || "$(git -C ${TMP_DCK} rev-parse HEAD)" != "$(git -C ${TMP_DCK} rev-parse ${MARLIN_DOCKER_BUILDER_REF})" ]]; then
  echo "Cloning Marlin from GitHub to ${TMP_DCK}"
  git clone --depth=1 --single-branch --branch "${MARLIN_DOCKER_BUILDER_REF}" ${MARLIN_SRC_REPO} "${TMP_DCK}" || { printf "\n\033[0;31mFailed to clone Marlin Docker builder\033[0m\n"; exit 1; }
else
  echo "Using cached docker-compose.yml"
  git -C ${TMP_DCK} reset --hard HEAD
fi

# Configure build #

printf "\n\033[0;32mInjecting Configuration\033[0m\n"

cp --remove-destination --verbose config/*.h ${TMP_SRC}/Marlin/

printf "\n\033[0;32mSetting up Docker\033[0m\n"

cp --remove-destination --verbose ${TMP_DCK}/docker-compose.yml ${TMP_SRC}/

cd "${TMP_SRC}"

docker compose build
docker compose run --rm marlin /code/buildroot/bin/format_code

printf "\n\033[0;32mCompiling Marlin for %s\033[0m\n" "${PLATFORM}"

docker compose run --rm marlin platformio run --target clean -e "${PLATFORM}"
docker compose run --rm marlin platformio run -e "${PLATFORM}" --silent

printf "\n\033[0;32mCopying compiled firmware\033[0m\n"

find "${TMP_SRC}/.pio/build/${PLATFORM}" -name "firmware-*.bin" -exec cp --remove-destination --verbose '{}' "${WORKING_DIR}/${FIRMWARE_NAME}" \;
if [[ ! -e "${WORKING_DIR}/${FIRMWARE_NAME}" ]]; then
  printf "\n\033[0;31m => Firmware compilation failed, check logs <=\033[0m\n\n"
  exit 1
fi

printf "\n\033[0;32mFirmware successfully compiled\033[0m\n"

printf "\n\033[0;32m => ${FIRMWARE_NAME} <=\033[0m\n\n"

