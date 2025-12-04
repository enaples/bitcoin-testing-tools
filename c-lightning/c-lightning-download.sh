#!/bin/bash

# Get the machine architecture
architecture=$(uname -m)

# Check the architecture and print the corresponding message
case $architecture in
    x86_64)
        CL_FILE=clightning-v${CL_VER}-Ubuntu-20.04-amd64.tar.xz 
        echo "Installing Core-Lightning ${CL_VER} for x86_64"
        cd /tmp && \
        curl -# -sLO https://github.com/ElementsProject/lightning/releases/download/v${CL_VER}/${CL_FILE}
        curl -# -sLO https://github.com/ElementsProject/lightning/releases/download/v${CL_VER}/SHA256SUMS
        curl -# -sLO https://github.com/ElementsProject/lightning/releases/download/v${CL_VER}/SHA256SUMS.asc

        /usr/local/bin/import-keys.sh
        
        gpg --verify /tmp/SHA256SUMS.asc && \
        cd /tmp && grep "${CL_FILE}" /tmp/SHA256SUMS | sha256sum -c -
        cd / && tar -xvf /tmp/${CL_FILE}
        
        echo "alias lightning-cli=\"lightning-cli --lightning-dir=/lightningd\"
        [[ \$PS1 && -f /usr/share/bash-completion/bash_completion ]] && \\
        . /usr/share/bash-completion/bash_completion" >> "/root/.bashrc"
        
    ;;
    aarch64|arm64)
        echo "Executables not available for Core-Lightning ${CL_VER} for ${architecture}"
        echo "Compiling the source code..."
        
        cd /tmp && \
        git clone --depth=1 --branch v${CL_VER} https://github.com/ElementsProject/lightning.git

        /usr/local/bin/import-keys.sh

        cd /tmp/lightning && \
        # cln v23.02 was signed by Alex Myers whose key is not under /contrib/keys
        # git verify-tag v${CL_VER} && \
        ./configure --enable-experimental-features --enable-developer && \
        make && \
        make install
        
        echo "alias lightning-cli=\"lightning-cli --lightning-dir=/lightningd\"
        [[ \$PS1 && -f /usr/share/bash-completion/bash_completion ]] && \\
        . /usr/share/bash-completion/bash_completion" >> "/root/.bashrc"

    ;;
esac
