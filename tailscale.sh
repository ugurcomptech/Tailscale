#!/bin/bash
set -e

echo "Tailscale repository ekleniyor..."
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

echo "Paketler güncelleniyor ve Tailscale kuruluyor..."
sudo apt-get update
sudo apt-get install -y tailscale

echo "Tailscale başlatılıyor..."
sudo tailscale up --ssh

echo "UFW üzerinden Tailscale SSH portu açılıyor..."
sudo ufw allow in on tailscale0 to any port 22 proto tcp

echo "Mevcut UFW kuralları listeleniyor ve tailscale0 dışındaki 22 portu kuralları siliniyor..."
sudo ufw status numbered | grep '22/tcp' | while read -r line; do
    rule_number=$(echo "$line" | awk -F'[][]' '{print $2}')
    if ! echo "$line" | grep -q 'tailscale0'; then
        echo "Kural $rule_number siliniyor: $line"
        sudo ufw --force delete "$rule_number"
    fi
done

echo "İşlem tamamlandı."
