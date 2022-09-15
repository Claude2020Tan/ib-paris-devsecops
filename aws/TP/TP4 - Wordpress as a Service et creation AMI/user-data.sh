#!/bin/bash
sudo systemctl start docker
docker-compose -f /home/ec2-user/wordpress/docker-compose.yaml up -d