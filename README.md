# DNS na AWS

## AWS - uruchamianie instancji EC2
![image](https://github.com/user-attachments/assets/09cae5d3-9116-4d6d-bd0c-df7ac63d861c)
![image](https://github.com/user-attachments/assets/8175ce4a-b02b-44eb-9c51-53dfcba81b32)
![image](https://github.com/user-attachments/assets/dd07fcd4-832e-4926-b7fa-c322056b4252)

Najlepiej skorzystać z usługi elastic IP, aby adres był statyczny.

![image](https://github.com/user-attachments/assets/f31069d9-ab62-4056-ae7a-4d20f7e8f5df)

## Porty używane przez `AdGuardHome`
Pamiętaj aby dodać potrzebne porty do firewalla w AWS.
Porty dla obu `TCP` i `UDP`, chyba że napisano inaczej.

- `3000` - port do początkowej konfiguracji serwera
- `53` - nieszyfrowany DNS
- `67`, `68` - DHCP, w naszym przypadku nie potrzebne
- `80`, `443` - admin Panel
- `443` - DNS over HTTPS
- `853` - DNS over TLS
- `443`, `784 (tylko udp)`, `853` - DNS over QUIC
- `5443` - DNSCrypt

## Podstawowa konfiguracja instancji
(Na AWS można wkleić w User data podczas tworzenia instancji)
### Amazon Linux 2023
```bash
#!/usr/bin/env bash

sudo yum update -y
sudo yum install -y docker

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

sudo systemctl enable --now docker
sudo usermod -a -G docker ec2-user
```
### Debian
```bash
#!/usr/bin/env bash

sudo apt-get update
sudo apt-get upgrade -y

# Add Docker's official GPG key:
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker and Compose plugin
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Docker-Compose standalone
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

sudo systemctl enable --now docker
sudo usermod -a -G docker admin
```

## SSH do maszyn
### Amazon Linux 2023
```shell
ssh ec2-user@<ip_addr> -i <key>.pem
```
### Debian
```shell
ssh admin@<ip_addr> -i <key>.pem
```

## AdGuardHome - DNS
### TL;DR
```shell
sudo mkdir -p /opt/adguardhome &&
sudo curl -s "https://raw.githubusercontent.com/P3Zer0/DNS-cloud-server/main/adguardhome.Dockerfile" --output /opt/adguardhome/adguardhome.Dockerfile
```
### Dłuższa wersja
```bash
sudo mkdir -p /opt/adguardhome
sudo nano /opt/adguardhome/adguardhome.Dockerfile
```
```yaml
# adguardhome.Dockefile
services:
  adguardhome:
    image: adguard/adguardhome:v0.107.59
    restart: unless-stopped
    volumes:
      - /opt/adguardhome/work:/opt/adguardhome/work
      - /opt/adguardhome/conf:/opt/adguardhome/conf
      - /opt/lego/:/opt/lego
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
      - "443:443/tcp"
      - "443:443/udp"
      - "3000:3000/tcp"
      - "853:853/tcp"
      - "853:853/udp"
      - "784:784/udp"
      - "8853:8853/udp"
      - "5443:5443/tcp"
      - "5443:5443/udp"
```

## `adguardhome.service`
### TL;DR
```shell
sudo curl -s "https://raw.githubusercontent.com/P3Zer0/DNS-cloud-server/main/adguardhome.service" --output /etc/systemd/system/adguardhome.service &&
sudo systemctl daemon-reload &&
sudo systemctl enable --now adguardhome
```
### Dłuższa wersja
```bash
sudo nano /etc/systemd/system/adguardhome.service
```
```ini
# adguardhome.service
[Unit]
Description=AdGuardHome via Docker Compose
Requires=docker.service
After=docker.service

[Service]
WorkingDirectory=/opt/adguardhome
ExecStart=/usr/local/bin/docker-compose -f adguardhome.Dockerfile up
ExecStop=/usr/local/bin/docker-compose -f adguardhome.Dockerfile down
Restart=always
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now adguardhome
```

## Zwalnianie portu 53
Sprawdź, czy port 53 jest już zajęty przez jakąś usługę
```bash
ss -tulnp
```
Jeśli tak to zwolnij go i ponownie uruchom adguardhome
```bash
sudo systemctl disable --now systemd-resolved &&
sudo systemctl start adguardhome
```

## Początkowa konfiguracja DNS
Należy wejść na `<server_ip>:3000` w przeglądarkce i wykonać podstawową konfigurację.

Później do kongiguracji używane będa porty `80` i `443`.

## Konfiguracja DNSa według uznania

### Ad listy
- https://discourse.pi-hole.net/t/recommended-adlists-to-use-2024/68434/2
- https://www.reddit.com/r/pihole/comments/1hy05nx/best_simple_adlist_now_we_are_in_2025/?rdt=48446
- https://github.com/hagezi/dns-blocklists
- https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
- https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt
- https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts
- https://v.firebog.net/hosts/static/w3kbl.txt
- https://adaway.org/hosts.txt
- https://v.firebog.net/hosts/AdguardDNS.txt
- https://v.firebog.net/hosts/Admiral.txt
- https://v.firebog.net/hosts/Easyprivacy.txt
- https://v.firebog.net/hosts/Prigent-Ads.txt
- https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt

### Malware listy
- https://cert.pl/lista-ostrzezen/
- https://hosts.tweedge.net/malicious.txt

## [Dodatkowe] Podpięcie do domeny, Certyfikaty, DoH, DoT, DoQ
### Rejestracja domeny
Można to zrobić w wielu różnych serwisach, tutaj jako przykład będzie używany `GoDaddy.com`.
![Screenshot_20250324_190051](https://github.com/user-attachments/assets/13222c0f-cdcf-4d16-86f3-b41a045e583a)

Następnie na stronie rejestratora naszej domeny należyt dodać dwa wpisy `A` do DNS - `@` oraz `*`, wskazujące na adres IP naszego serwera.
![Screenshot_20250324_190143](https://github.com/user-attachments/assets/820971b3-a5bc-4167-997e-5d70acaabb96)

### Generowanie certyfikatów TLS przy pomocy [`Let's Encrypt`](https://letsencrypt.org/) oraz [`Lego`](https://go-acme.github.io/lego/)
#### Generowanie kluczy API
Różni się to zależnie od rejestratora domeny.

Dla `GoDaddy` - https://developer.godaddy.com/keys

![image](https://github.com/user-attachments/assets/4848a047-de43-4745-8a8c-6817583cbf95)
![Screenshot_20250324_192106](https://github.com/user-attachments/assets/a756947a-49b0-4480-a9c6-a011a0c16b1c)

#### Użycie skryptu od twórców `AdGuardHome`
Szczegółowe instrukcje znajdują się [tutaj](https://github.com/ameshkov/legoagh).

Dla `GoDaddy`
```bash
sudo mkdir /opt/lego
cd /opt/lego
sudo curl -s "https://raw.githubusercontent.com/ameshkov/legoagh/master/lego.sh" --output lego.sh
sudo chmod +x lego.sh
```
```bash
sudo DOMAIN_NAME="<your_domain>" \
		EMAIL="<your_email>" \
		DNS_PROVIDER="godaddy" \
		GODADDY_API_KEY="<api_key>" \
		GODADDY_API_SECRET="<api_secret>" \
		./lego.sh
```
![Screenshot_20250324_133134](https://github.com/user-attachments/assets/afb0008a-3e7a-4183-89a7-22ca521432d6)


#### Użycie `Lego` bezpośrednio
Szczegółowe instrukcje znajdują się [tutaj](https://go-acme.github.io/lego/).

#### Włączenie szyfrowania w `AdGuardHome` (Https, DoH, DoT, DoQ)

![image](https://github.com/user-attachments/assets/184db586-fc10-45e2-a460-06355613a773)
![Screenshot_20250324_182421](https://github.com/user-attachments/assets/8e51ce9c-e178-48fb-a574-11436256542d)
![Screenshot_20250324_182431](https://github.com/user-attachments/assets/ec220bcb-937f-4b5a-bbd1-fcc5dd9eca00)


## Zrzuty ekranu

![Screenshot_20250324_182358](https://github.com/user-attachments/assets/589fe39f-b5d3-4f66-b8e5-878e548ddda5)
![image](https://github.com/user-attachments/assets/bf89e161-6b0f-484f-88f3-c44cbee9ff63)
![Screenshot_20250324_195726](https://github.com/user-attachments/assets/a31863ab-5083-4b4d-b7d8-7a31c6a84991)
![Screenshot_20250324_195740](https://github.com/user-attachments/assets/321f59e8-f226-4ec9-9413-6fb078388999)


## Źródła
- https://github.com/AdguardTeam/AdGuardHome
- https://hub.docker.com/r/adguard/adguardhome
- https://go-acme.github.io/lego/
- https://github.com/ameshkov/legoagh/tree/master
- https://adguard.com/en/blog/adguard-home-on-public-server.html
- https://medium.com/@life-is-short-so-enjoy-it/homelab-adguard-enable-dnssec-what-is-it-c93067ff313d
- https://www.cloudflare.com/learning/dns/dns-over-tls/
