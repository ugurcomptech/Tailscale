# Tailscale Kullanım Rehberi

Bu rehber, Tailscale’in Ubuntu üzerinde kurulumu, SSH ile güvenli kullanımı ve genel mimarisi hakkında detaylı bilgiler içerir. Ayrıca, otomatik SSH kurulum scripti de dahil edilmiştir.

---

## 1. Tailscale Nedir?

Tailscale, **WireGuard tabanlı bir VPN** çözümüdür.  
- Kendi cihazlarını birbirine bağlayan **mesh VPN ağı** oluşturur.  
- Her cihaz, **100.x.x.x tarzında bir Tailscale IP** alır.  
- NAT veya firewall sorunlarını otomatik çözer.  
- Tailscale SSH ile parola sormadan güvenli bağlantı sağlar.

### Ağ Mimarisi

```
+-----------------+      +-----------------+
|    Cihaz A      | <--> |    Cihaz B      |
| Tailscale IP:   |      | Tailscale IP:   |
| 100.76.31.48    |      | 100.71.128.10   |
+-----------------+      +-----------------+
        ^                        ^
        |                        |
   Tailscale Network           Tailscale Network
        |                        |
      Internet (şifreli WireGuard)
```

- Her cihaz birbirini **Tailscale IP’si üzerinden tanır**.  
- Başka kullanıcıların cihazları senin ağına katılmadığı sürece erişemez.

---

## 2. Tailscale Hesabı Oluşturma

1. [Tailscale web sitesine](https://tailscale.com/) git.  
2. Google, Microsoft, GitHub veya SSO ile kayıt ol.  
3. Yeni bir cihaz eklemek için **authkey** oluştur:  

```bash
tailscale key generate
```
- Bu anahtar, script veya manuel kurulum sırasında kullanılabilir.

---

## 3. Ubuntu Üzerinde Kurulum

### Adım 1: Depo ve Key Ekleme

```bash
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
```

### Adım 2: Paketleri Güncelle ve Tailscale Kur

```bash
sudo apt-get update
sudo apt-get install -y tailscale
```

### Adım 3: Tailscale’i Başlat ve SSH Aktif Et

```bash
sudo tailscale up --ssh
```

---

## 4. SSH Güvenliği ve UFW

- Tailscale SSH ile parola sormadan bağlantı sağlanabilir.  
- Public IP üzerinden SSH’yi engellemek için UFW kullan:

```bash
sudo ufw allow in on tailscale0 to any port 22 proto tcp
```

- Tailscale dışındaki interface’lerde 22 portunu kapat:

```bash
sudo ufw status numbered | grep '22/tcp'
sudo ufw --force delete <kural_numarası>
```

- Tailscale IP’leri üzerinden sadece belirli cihazları izinli yapmak için:

```bash
sudo ufw allow in on tailscale0 from 100.76.31.48 to any port 22 proto tcp
```

---

## 5. SSH Kurulum Scripti

Aşağıdaki script, Tailscale kurulumu, SSH ayarlarını ve UFW kurallarını otomatik yapar.

```bash
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
```

---

## Okuduğunuz için teşekkürler.
