#!/usr/bin/env bash
#
# NAMYDEV UDP-Custom Installer
# https://github.com/namydeveloper/UDP-Custom
#

set -e

clear
echo "=============================================="
echo "     🔰 NAMYDEV UDP-CUSTOM INSTALLER 🔰"
echo "=============================================="
echo ""

# Cek versi Ubuntu dengan benar
if lsb_release -rs | grep -Eq '^(8|9|10|11|16\.04|18\.04)'; then
  apt-get update
  apt-get install -y curl wget screen iptables
else
  echo " ⇢ Mengatur zona waktu ke Asia/Jakarta"
  ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

  echo " ⇢ Update & Install dependencies..."
  apt update -y
  apt install -y curl wget screen iptables iproute2

  echo " ⇢ Menghapus layanan bawaan"
  systemctl stop udp-custom.service 2>/dev/null || true
  systemctl disable udp-custom.service 2>/dev/null || true
  rm -f /etc/systemd/system/udp-custom.service

  echo " ⇢ Download module utama..."
  source <(curl -sSL 'https://raw.githubusercontent.com/namydeveloper/UDP-Custom/main/module/module')

  echo " ⇢ Download file konfigurasi awal..."
  mkdir -p /root/udp
  wget -qO /root/udp/config.json "https://raw.githubusercontent.com/namydeveloper/UDP-Custom/main/config/config.json"

  echo " ⇢ Download file utama script UDP..."
  wget -qO /usr/local/bin/udp "https://raw.githubusercontent.com/namydeveloper/UDP-Custom/main/udp.sh"
  chmod +x /usr/local/bin/udp

  echo " ⇢ Download & install hysteria binary..."
  curl -sLo /usr/local/bin/hysteria https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64
  chmod +x /usr/local/bin/hysteria
fi

# Fungsi untuk memblokir user duplikat (dengan IP sama)
check_and_block_users() {
  echo "⇢ Mengecek IP duplikat dan memblokir..."
  users=$(who | grep -oP '\(\K[^\)]+' | sort | uniq -c | awk '$1 > 1 {print $2}')
  for ip in $users; do
    iptables -A INPUT -s "$ip" -j DROP
  done
}

# Jalankan blokir
check_and_block_users

# Hapus script installer setelah selesai
rm -f /home/ubuntu/install.sh 2>/dev/null || true

# Output informasi sukses
echo ""
echo -e "✅ \033[1;32mUDP-Custom berhasil diinstal!\033[0m"
echo -e "📦 Jalankan menu: \033[1;36mudp\033[0m"
echo -e "📢 Telegram Support: \033[1;36m@Namydev\033[0m"
echo ""
