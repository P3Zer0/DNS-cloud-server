#!/usr/bin/env bash

sudo yum update -y
sudo yum install -y docker

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

sudo systemctl enable --now docker
sudo usermod -a -G docker ec2-user
