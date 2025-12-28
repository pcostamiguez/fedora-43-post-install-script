#!/bin/bash

# ==============================================================================
# SCRIPT DE PÓS-INSTALAÇÃO FEDORA 43+ (COMPATÍVEL DNF5)
# ==============================================================================

# -----------------------------------------------------------------------------
# Data: 1 de dezembro de 2025
# Autor: Xerxes Lins (vivaolinux.com.br/~xerxeslins)
# Modificado por: PHCM (vivaolinux.com.br/~pedrola)
# Revisão técnica e hardening: 2025
# Versão: 2.2
# Descrição: Script de pós instalação do Fedora Workstation 43+.
# -----------------------------------------------------------------------------

# Cores
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
SEM_COR='\033[0m'

USUARIO_REAL=${SUDO_USER:-$USER}

imprimir_cabecalho() {
    clear
    echo -e "${AZUL}==========================================================${SEM_COR}"
    echo -e "${AZUL}      PÓS-INSTALAÇÃO FEDORA (SCRIPT BLINDADO)             ${SEM_COR}"
    echo -e "${AZUL}==========================================================${SEM_COR}"
    echo -e "Usuário: ${AMARELO}$USUARIO_REAL${SEM_COR}"
    echo ""
}

perguntar() {
    while true; do
        echo -e "${AMARELO}[?] $1 (s/n)${SEM_COR}"
        read -r opcao
        case $opcao in
            [sS]* ) return 0;;
            [nN]* ) return 1;;
            * ) echo "Digite 's' ou 'n'.";;
        esac
    done
}

if [[ $EUID -ne 0 ]]; then
   echo -e "${VERMELHO}ERRO: Rode com sudo.${SEM_COR}"
   exit 1
fi

imprimir_cabecalho

# ------------------------------------------------------------------------------
# 1. DNF (OTIMIZAÇÃO)
# ------------------------------------------------------------------------------
if perguntar "Otimizar DNF (downloads paralelos)?"; then
    sed -i '/max_parallel_downloads/d' /etc/dnf/dnf.conf
    sed -i '/defaultyes/d' /etc/dnf/dnf.conf
    echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
    echo "defaultyes=True" >> /etc/dnf/dnf.conf
    echo -e "${VERDE}DNF otimizado.${SEM_COR}"
fi

# ------------------------------------------------------------------------------
# 2. RPM FUSION
# ------------------------------------------------------------------------------
if perguntar "Habilitar RPM Fusion (codecs e drivers)?"; then
    dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    echo -e "${VERDE}RPM Fusion habilitado.${SEM_COR}"
fi

# ------------------------------------------------------------------------------
# 3. CODECS MULTIMÍDIA
# ------------------------------------------------------------------------------
if perguntar "Instalar codecs multimídia?"; then
    dnf install -y \
        ffmpeg \
        libavcodec-freeworld \
        gstreamer1-plugins-bad-free-extras \
        gstreamer1-plugins-bad-freeworld \
        gstreamer1-plugins-ugly \
        gstreamer1-vaapi \
        gstreamer1-plugin-openh264 \
        mozilla-openh264 \
        @multimedia --skip-unavailable
    echo -e "${VERDE}Codecs instalados.${SEM_COR}"
fi

# ------------------------------------------------------------------------------
# 4. FLATHUB
# ------------------------------------------------------------------------------
if perguntar "Habilitar Flathub?"; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo -e "${VERDE}Flathub habilitado.${SEM_COR}"
fi

# ------------------------------------------------------------------------------
# 5. NAVEGADORES
# ------------------------------------------------------------------------------
echo -e "${AZUL}--- NAVEGADORES ---${SEM_COR}"

if perguntar "Instalar Google Chrome?"; then
    dnf install -y fedora-workstation-repositories
    rpm --import https://dl.google.com/linux/linux_signing_key.pub
    dnf config-manager setopt google-chrome.enabled=1
    dnf install -y google-chrome-stable
fi

if perguntar "Instalar Microsoft Edge?"; then
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    cat > /etc/yum.repos.d/microsoft-edge.repo <<EOF
[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    dnf install -y microsoft-edge-stable
fi

if perguntar "Instalar Brave Browser?"; then
    rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    cat > /etc/yum.repos.d/brave-browser.repo <<EOF
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF
    dnf install -y brave-browser
fi

# ------------------------------------------------------------------------------
# 6. TELEGRAM (OFICIAL)
# ------------------------------------------------------------------------------
if perguntar "Instalar Telegram Desktop (oficial)?"; then
    cd /tmp || exit 1
    wget -O telegram.tar.xz https://telegram.org/dl/desktop/linux
    rm -rf /opt/Telegram
    tar -xf telegram.tar.xz
    mv Telegram /opt/
    ln -sf /opt/Telegram/Telegram /usr/bin/telegram
fi

# ------------------------------------------------------------------------------
# 7. GNOME TWEAKS E EXTENSÕES
# ------------------------------------------------------------------------------
if perguntar "Instalar GNOME Tweaks e utilitários GNOME?"; then
    dnf install -y gnome-tweaks gnome-extensions-app
fi

# ------------------------------------------------------------------------------
# 8. SUPORTE A APPIMAGE (FUSE)
# ------------------------------------------------------------------------------
if perguntar "Habilitar suporte a AppImage (FUSE)?"; then
    dnf install -y fuse fuse-libs
fi

# ------------------------------------------------------------------------------
# 9. EXTENSION MANAGER (FLATPAK)
# ------------------------------------------------------------------------------
if perguntar "Instalar Extension Manager (Flatpak)?"; then
    flatpak install -y flathub com.mattjakeman.ExtensionManager
fi

# ------------------------------------------------------------------------------
# 10. APLICAÇÕES ESSENCIAIS
# ------------------------------------------------------------------------------
if perguntar "Instalar aplicações essenciais (VLC, Steam, GIMP etc.)?"; then
    dnf install -y \
        vlc \
        steam \
        transmission \
        gimp \
        geary \
        unzip \
        p7zip \
        p7zip-plugins \
        unrar
fi

# ------------------------------------------------------------------------------
# 11. NVIDIA (FORÇAR NVIDIA ONLY - SEM BIOS)
# ------------------------------------------------------------------------------
if perguntar "Instalar NVIDIA proprietário e desativar GPU AMD (NVIDIA ONLY)?"; then
    dnf install -y kernel-devel kernel-headers
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-settings nvidia-powerd

    echo -e "${AZUL}Compilando módulos NVIDIA...${SEM_COR}"
    akmods --force

    grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"

    cat > /etc/modprobe.d/blacklist-amdgpu.conf <<EOF
blacklist amdgpu
options amdgpu modeset=0
EOF

    cat > /etc/modprobe.d/nvidia.conf <<EOF
options nvidia-drm modeset=1
EOF

    dracut --force
    echo -e "${VERDE}NVIDIA configurada (AMD desativado).${SEM_COR}"
fi

# ------------------------------------------------------------------------------
# 12. ATUALIZAÇÃO FINAL
# ------------------------------------------------------------------------------
if perguntar "Atualizar o sistema agora?"; then
    dnf update -y
    dnf autoremove -y
fi

# ------------------------------------------------------------------------------
# FINAL
# ------------------------------------------------------------------------------
echo ""
echo -e "${VERDE}SCRIPT CONCLUÍDO COM SUCESSO.${SEM_COR}"
echo -e "${AMARELO}Reinicie o sistema para aplicar todas as alterações.${SEM_COR}"
