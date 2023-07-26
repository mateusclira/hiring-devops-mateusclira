#!/bin/bash

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings 
 
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
 

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
 
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

export MONGODB_ADDON_URI="mongodb://meteorhiring:meteorhiring@ac-nhcvxhf-shard-00-00.bebrwbu.mongodb.net:27017/message?ssl=false&authSource=admin&replicaSet=atlas-1jchvv-shard-0"

sudo docker run -e MONGODB_ADDON_URI=$MONGODB_ADDON_URI -d -p 80:80 mateusclira/meteorapp:v4 
