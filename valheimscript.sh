# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

sudo apt update && sudo apt upgrade -y 
sudo apt install unzip apt-transport-https ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg -y
sudo apt update

#install AWS CLI
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install

#create random string for password
VHPW=$(echo $RANDOM | md5sum | head -c 20)

#get stackname created by user data script and update SSM parameter name with this to make it unique
STACKNAME=$(</tmp/mcParamName.txt)
PARAMNAME=mcValheimPW-$STACKNAME

#put random string into parameter store as encrypted string value
aws ssm put-parameter --name $PARAMNAME --value $VHPW --type "SecureString" --overwrite


#install docker and valheim app on docker
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo apt install docker-compose -y
sudo usermod -aG docker $USER
sudo mkdir /usr/games/serverconfig
cd /usr/games/serverconfig
sudo bash -c 'echo "version: \"3\"
services:
  valheim-server:
    image: ghcr.io/lloesche/valheim-server
    ports:
      - 2456:2456/udp
      - 2457:2457/udp
      - 2458:2458/udp
    environment:
      - SERVER_PORT=2456
      - SERVER_NAME="Muurtje"
      - SERVER_PUBLIC = false
      - WORLD_NAME="Valschwein"
      - SERVER_PASS='"$VHPW"'
      - TZ=Europe/London
      - UPDATE_CRON="0 1 * * *"
      - RESTART_CRON="0 5 * * *"
      - BACKUPS=true
      - BACKUPS_CRON="*/15 * * * *"
      - BACKUPS_DIRECTORY="/config/backups"
      - BACKUPS_MAX_AGE=21
      - BACKUPS_MAX_COUNT=10
      - BACKUPS_IF_IDLE=false
      - BACKUPS_IDLE_GRACE_PERIOD=3600
      - BACKUPS_ZIP=true
      - PERMISSIONS_UMASK="022"
      - STEAMCMD_ARGS="validate"
      - VALHEIM_PLUS=true
      - VALHEIM_PLUS_RELEASE="latest"
      - CAP_SYS_NICE=true
    volumes:
      - ./valheim-server/config:/config
      - ./valheim-server/data:/opt/valheim >> docker-compose.yml'
echo "@reboot root (cd /usr/games/serverconfig/ && docker-compose up)" > /etc/cron.d/awsgameserver
sudo docker-compose up
