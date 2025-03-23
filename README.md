# DNS na AWS

## AWS setup
![image](https://github.com/user-attachments/assets/09cae5d3-9116-4d6d-bd0c-df7ac63d861c)
![image](https://github.com/user-attachments/assets/8175ce4a-b02b-44eb-9c51-53dfcba81b32)
![image](https://github.com/user-attachments/assets/dd07fcd4-832e-4926-b7fa-c322056b4252)
![image](https://github.com/user-attachments/assets/f31069d9-ab62-4056-ae7a-4d20f7e8f5df)
![image](https://github.com/user-attachments/assets/4848a047-de43-4745-8a8c-6817583cbf95)

## Dockerfile
```yaml
# adguardhome.Dockefile
services:
  adguardhome:
    image: adguard/adguardhome
    restart: unless-stopped
    volumes:
      - /opt/adguardhome/work:/opt/adguardhome/work
      - /opt/adguardhome/conf:/opt/adguardhome/conf
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
      - "443:443/tcp"
      - "443:443/udp"
      - "3000:3000/tcp"
      - "853:853/tcp"
      - "784:784/udp"
      - "853:853/udp"
      - "8853:8853/udp"
      - "5443:5443/tcp"
      - "5443:5443/udp"
```

## Amazon Linux 2023 setup
```bash
sudo yum update -y
sudo yum install -y docker

sudo systemctl enable --now docker
sudo usermod -a -G docker ec2-user

# instalacja compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version
```

## `adguardhome.service` w Amazon Linux 2023
```bash
cp adguardhome.Dockefile /opt/adguardhome/
```
```bash
sudo nano /etc/systemd/system/adguardhome.service
```
```ini
[Unit]
Description=AdGuard Home via Docker Compose
Requires=docker.service
After=docker.service

[Service]
WorkingDirectory=/opt/adguardhome
ExecStart=/usr/local/bin/docker-compose -f adguardhome.Dockefile up
ExecStop=/usr/local/bin/docker-compose -f adguardhome.Dockefile down
Restart=always
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now adguardhome
```

## Ad listy
- https://discourse.pi-hole.net/t/recommended-adlists-to-use-2024/68434/2
- https://www.reddit.com/r/pihole/comments/1hy05nx/best_simple_adlist_now_we_are_in_2025/?rdt=48446
- https://cert.pl/lista-ostrzezen/
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
- https://hosts.tweedge.net/malicious.txt

## Certy 
- TODO

## Zrzuty ekranu

![image](https://github.com/user-attachments/assets/bf89e161-6b0f-484f-88f3-c44cbee9ff63)

