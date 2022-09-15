#!/bin/bash
sudo yum install git -y
git clone https://github.com/diranetafen/cursus-devops.git
cd ./cursus-devops/tower/
tar -xzvf awx.tar.gz -C ~/
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker vagrant
sudo systemctl start docker
sudo systemctl enable docker
sudo yum install docker-compose -y
sudo docker-compose  -f /home/vagrant/.awx/awxcompose/docker-compose.yml up -d
