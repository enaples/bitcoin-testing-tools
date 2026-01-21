#!/bin/bash

# Get the machine architecture
architecture=$(uname -m)

# Check the architecture and print the corresponding message
case $architecture in
    x86_64)
        CLN_FILE=clightning-v${CLN_VER}-Ubuntu-20.04-amd64.tar.xz 
        echo "Installing Core-Lightning ${CLN_VER} for x86_64"
        cd /tmp && \
        curl -# -sLO https://github.com/ElementsProject/lightning/releases/download/v${CLN_VER}/${CLN_FILE}
        curl -# -sLO https://github.com/ElementsProject/lightning/releases/download/v${CLN_VER}/SHA256SUMS
        curl -# -sLO https://github.com/ElementsProject/lightning/releases/download/v${CLN_VER}/SHA256SUMS.asc

        /usr/local/bin/import-keys.sh
        
        gpg --verify /tmp/SHA256SUMS.asc && \
        cd /tmp && grep "${CLN_FILE}" /tmp/SHA256SUMS | sha256sum -c -
        cd / && tar -xvf /tmp/${CLN_FILE}
        
        echo "alias lightning-cli=\"lightning-cli --lightning-dir=/lightningd\"
        [[ \$PS1 && -f /usr/share/bash-completion/bash_completion ]] && \\
        . /usr/share/bash-completion/bash_completion" >> "/root/.bashrc"
        
    ;;
    aarch64|arm64)
        echo "Executables not available for Core-Lightning ${CLN_VER} for ${architecture}"
        echo "Compiling the source code..."
        
        cd /tmp && \
        git clone --depth=1 --branch v${CLN_VER} https://github.com/ElementsProject/lightning.git

        /usr/local/bin/import-keys.sh

        cd /tmp/lightning && \
        # cln v23.02 was signed by Alex Myers whose key is not under /contrib/keys
        # git verify-tag v${CLN_VER} && \
        ./configure && \
        RUST_PROFILE=release uv run make && \
        RUST_PROFILE=release make install
        
        echo "alias lightning-cli=\"lightning-cli --lightning-dir=/lightningd\"
        [[ \$PS1 && -f /usr/share/bash-completion/bash_completion ]] && \\
        . /usr/share/bash-completion/bash_completion" >> "/root/.bashrc"

    ;;
esac
