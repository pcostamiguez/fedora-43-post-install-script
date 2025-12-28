#!/bin/bash

# ==============================================================================
# SCRIPT DE PÓS-INSTALAÇÃO FEDORA 43+ (COMPATÍVEL DNF5)
# ==============================================================================

# -----------------------------------------------------------------------------
# Data: 1 de dezembro de 2025
# Autor: Xerxes Lins (vivaolinux.com.br/~xerxeslins)
# Versão: 2.0
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
    echo -e "${AZUL}      PÓS-INSTALAÇÃO FEDORA (SCRIPT V4 BLINDADO)          ${SEM_COR}"
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

# 1. DNF (Limpeza e Otimização)
if perguntar "Otimizar DNF (Downloads paralelos)?"; then
    sed -i '/max_parallel_downloads/d' /etc/dnf/dnf.conf
    sed -i '/defaultyes/d' /etc/dnf/dnf.conf
    echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
    echo "defaultyes=True" >> /etc/dnf/dnf.conf
    echo -e "${VERDE}DNF Otimizado.${SEM_COR}"
    sleep 1
fi

# 2. RPM FUSION
if perguntar "Habilitar RPM FUSION (Codecs/Drivers)?"; then
    dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
    dnf install @core -y
    echo -e "${VERDE}RPM Fusion OK.${SEM_COR}"
fi

# 3. CODECS
if perguntar "Instalar Codecs Multimídia (FFmpeg, GStreamer)?"; then
    echo "Instalando pacotes de mídia..."
    dnf install ffmpeg libavcodec-freeworld -y
    dnf install gstreamer1-plugins-bad-free-extras gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly gstreamer1-vaapi -y
    dnf install @multimedia -y --skip-unavailable
    dnf install gstreamer1-plugin-openh264 mozilla-openh264 -y
    echo -e "${VERDE}Codecs instalados!${SEM_COR}"
fi

# 4. FLATHUB
if perguntar "Habilitar Flathub?"; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo -e "${VERDE}Flathub OK.${SEM_COR}"
fi

# 5. NAVEGADORES (MÉTODO REPO MANUAL - À PROVA DE DNF5)
echo -e "${AZUL}--- NAVEGADORES ---${SEM_COR}"

# Google Chrome (Correção de Chave GPG)
if perguntar "Instalar Google Chrome?"; then
    dnf install fedora-workstation-repositories -y
    # Importar chave antes para evitar erro de lock
    rpm --import https://dl.google.com/linux/linux_signing_key.pub
    # Habilitar via comando direto no DNF5
    dnf config-manager setopt google-chrome.enabled=1
    dnf install google-chrome-stable -y
    echo -e "${VERDE}Chrome OK.${SEM_COR}"
fi

# Microsoft Edge (Correção de Repositório Manual)
if perguntar "Instalar Microsoft Edge?"; then
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    # Criar arquivo .repo manualmente (Funciona em qualquer versão do DNF)
    echo -e "[microsoft-edge]\nname=Microsoft Edge\nbaseurl=https://packages.microsoft.com/yumrepos/edge\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/microsoft-edge.repo
    dnf install microsoft-edge-stable -y
    echo -e "${VERDE}Edge OK.${SEM_COR}"
fi

# Brave Browser (Correção de Repositório Manual)
if perguntar "Instalar Brave?"; then
    rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    # Criar arquivo .repo manualmente
    echo -e "[brave-browser]\nname=Brave Browser\nbaseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/\nenabled=1\ngpgcheck=1\ngpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc" > /etc/yum.repos.d/brave-browser.repo
    dnf install brave-browser -y
    echo -e "${VERDE}Brave OK.${SEM_COR}"
fi

# 6. TELEGRAM
if perguntar "Instalar Telegram (Oficial)?"; then
    echo "Baixando..."
    cd /tmp
    wget -O telegram.tar.xz https://telegram.org/dl/desktop/linux
    rm -rf /opt/Telegram
    tar -xf telegram.tar.xz
    mv Telegram /opt/
    ln -sf /opt/Telegram/Telegram /usr/bin/telegram
    
    cat > /usr/share/applications/telegram.desktop <<EOF
[Desktop Entry]
Name=Telegram Desktop
Comment=Official Telegram Desktop
Exec=/opt/Telegram/Telegram -- %u
Icon=telegram
Terminal=false
StartupWMClass=TelegramDesktop
Type=Application
Categories=Chat;Network;InstantMessaging;
MimeType=x-scheme-handler/tg;
EOF
    wget -O /usr/share/icons/hicolor/128x128/apps/telegram.png https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Telegram_logo.svg/1024px-Telegram_logo.svg.png
    echo -e "${VERDE}Telegram OK.${SEM_COR}"
fi

# 7. EXTRAS GNOME
if perguntar "Instalar Tweaks e Extensões?"; then
    dnf install gnome-tweaks gnome-extensions-app -y
    echo -e "${VERDE}Ferramentas OK.${SEM_COR}"
fi

# 8. MUDAR SENHA
if perguntar "Mudar senha do usuário $USUARIO_REAL?"; then
    echo -e "${AMARELO}Digite a nova senha:${SEM_COR}"
    passwd "$USUARIO_REAL"
fi

# 9. ATUALIZAÇÃO
if perguntar "Atualizar sistema agora?"; then
    dnf update -y
    dnf autoremove -y
    echo -e "${VERDE}Sistema atualizado.${SEM_COR}"
fi

echo ""
echo -e "${VERDE}SCRIPT CONCLUÍDO! REINICIE O PC.${SEM_COR}"
