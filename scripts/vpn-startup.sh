#! /bin/bash

# Create a TUN device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 0666 /dev/net/tun

# Create docker user
usermod -u $PUID docker_user
groupmod -g $PGID docker_group
chown -R docker_user:docker_group /config

# Start the PIA service

/opt/piavpn/bin/pia-daemon &
sleep 2

# Log in to PIA

echo -e "$PIA_USERNAME\n$PIA_PASSWORD" > /pia_credentials
piactl login /pia_credentials

if [ ! $? -eq 0 ]; then
    exit 5;
fi

# Enable background service operation

piactl background enable

if [ ! $? -eq 0 ]; then
    exit 5;
fi

# Set debug logging

piactl set debuglogging $PIA_DEBUG_LOGGING

if [ ! $? -eq 0 ]; then
    exit 5;
fi

piactl set protocol $PIA_PROTOCOL

if [ ! $? -eq 0 ]; then
    exit 5;
fi

piactl set requestportforward $PIA_PORT_FORWARD

if [ ! $? -eq 0 ]; then
    exit 5;
fi

# Connect to the VPN

piactl connect

if [ ! $? -eq 0 ]; then
    exit 5;
fi

# Wait for the connection to come up

i="0"
/opt/scripts/vpn-health-check.sh
while [[ ! $? -eq 0 ]]; do
    sleep 2
    echo "Waiting for the VPN to connect... $i"
    i=$[$i+1]
    if [[ $i -eq "10" ]]; then
        exit 5
    fi
    /opt/scripts/vpn-health-check.sh
done

export VPN_PORT=$(piactl get portforward)

# Run the setup script for the environment
/opt/scripts/app-setup.sh

# Run the user app in the docker container
su -g docker_group - docker_user -c "/opt/scripts/app-startup.sh"

