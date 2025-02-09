FROM python:3.9.0-buster

ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=marlinbuild

# Disable warnings about not having a TTY
ARG DEBIAN_FRONTEND=noninteractive

# Disable debconf warnings
ARG DEBCONF_NOWARNINGS="yes"

# Upgrade pip
RUN pip install --upgrade pip

# Install platformio toolchain / framework and pyyaml
RUN pip install -U platformio PyYaml

# Upgrade platformio using development version / branch
RUN pio upgrade --dev

# Set working directory
WORKDIR /code

# Set volumes / mount points that we are using
VOLUME /code

RUN groupadd -g ${USER_GID} ${USER_NAME}
RUN useradd -rm -d /code -g ${USER_GID} -u ${USER_UID} ${USER_NAME}

USER ${USER_NAME}
