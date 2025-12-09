#!/bin/bash

# Get the machine architecture
architecture=$(uname -m)

# Check the architecture and print the corresponding message
case $architecture in
    x86_64)
        ELEMENTS_FILE="elements-${ELEMENTSD_VER}-x86_64-linux-gnu.tar.gz"
        echo "Installing Elements ${ELEMENTSD_VER} for x86_64"
    ;;
    arm64)
        ELEMENTS_FILE="elements-${ELEMENTSD_VER}-osx-64.tar.gz"
        echo "Installing Elements ${ELEMENTSD_VER} for arm64"
    ;;
    aarch64)
        ELEMENTS_FILE="elements-${ELEMENTSD_VER}-aarch64-linux-gnu.tar.gz"
        echo "Installing Elements ${ELEMENTSD_VER} for aarch64"
    ;;
esac

# Install Elements binaries and libraries
cd /tmp && mkdir elements
cd /tmp/elements && \
curl -# -sLO https://github.com/ElementsProject/elements/releases/download/elements-${ELEMENTSD_VER}/${ELEMENTS_FILE} && \
curl -# -sLO https://github.com/ElementsProject/elements/releases/download/elements-${ELEMENTSD_VER}/SHA256SUMS && \
curl -# -sLO https://github.com/ElementsProject/elements/releases/download/elements-${ELEMENTSD_VER}/SHA256SUMS.asc && \

# Verify the integrity of the binaries
# TODO: add gpg verification on SHA256SUMS
gpg --keyserver keyserver.ubuntu.com --recv-keys DE10E82629A8CAD55B700B972F2A88D
sha256sum --ignore-missing --check SHA256SUMS.asc

cd /tmp/elements && grep "${ELEMENTS_FILE}" SHA256SUMS | sha256sum -c -

cd /tmp/elements && \
tar -zxf ${ELEMENTS_FILE} && \
cd elements-${ELEMENTSD_VER} && \
install -vD bin/* /usr/bin && \
install -vD lib/* /usr/lib && \
rm -rf /tmp/elements
