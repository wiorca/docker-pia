# Docker Private Internet Access Image

## About the image

PIA docker container, as a base for other images.  It does not forward any ports, has onely one volume for the docker_user, and exits immediately by default.

It contains health-checking, and a framework for extending the image however you like to serve your own purposes.  It just handles connecting to PIA for the moment, and making sure the connection remains active and secure.

This documentation format is inspired by the great people over at linuxserver.io.

## Extending the image

There are three script files placed in the /opt/scripts directory that are designed to be overwritten:

/opt/scripts/app-setup.sh

This script is designed to set up the environment for the running application. It is run as root, and should be used to prepare the environment for the running app.

/opt/scripts/app-startup.sh

This script is designed to start the user application after the connection to the VPN has been established.  This script should never exit, and will be run as docker_user:docker_group, with the UID and GID specified in PUID and GUID.

/opt/scripts/app-health-check.sh

This script will be run periodically to check the health of the container.  It MUST return 0 if the container is healthy.  Any other return value will fail.  It is called after the health check for the VPN is completed successfully.  Override as you wish.

## Usage

Here are some example snippets to help you get started creating a container.

### docker

```
docker create \
  --name=docker-pia \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e PIA_USERNAME=username \
  -e PIA_PASSWORD=password \
  -e PIA_DEBUG_LOGGING=false \
  -e PIA_PROTOCOL=openvpn \
  -e PIA_PORT_FORWARD=false \
  -e PIA_REGION=auto \
  -v /location/on/host:/config \
  --dns 8.8.8.8 \
  --cap-add NET_ADMIN \
  --restart unless-stopped \
  wiorca/docker-pia
```


### docker-compose

Compatible with docker-compose schemas.

```
---
version: "2.1"
services:
  docker-pia:
    image: wiorca/docker-pia
    container_name: docker-pia
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - PIA_USERNAME=username
      - PIA_PASSWORD=password
      - PIA_DEBUG_LOGGING=false
      - PIA_PROTOCOL=openvpn
      - PIA_PORT_FORWARD=false
      - PIA_REGION=auto
    volumes:
      - /location/on/host:/config
    dns:
      - 8.8.8.8
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

## Parameters

Container images are configured using parameters passed at runtime (such as those above).

| Parameter | Examples/Options | Function |
| :----: | --- | --- |
| PUID | 1000 | The nummeric user ID to run the application as, and assign to the user docker_user |
| PGID | 1000 | The numeric group ID to run the application as, and assign to the group docker_group |
| TZ=Europe/London | The timezone to run the container in |
| PIA_USERNAME | username | The username used to connect to PIA |
| PIA_PASSWORD | password | The password associated with the username |
| PIA_DEBUG_LOGGING | true/false | Enables or disables debug logging |
| PIA_PROTOCOL | openvpn, wireguard | The protocol to use when connecting to PIA, which must be on the protocol list |
| PIA_PORT_FORWARD | true/false | The port you have convigured to forward via PIA. Not used by this container, but made available |
| PIA_REGION | auto | The location to connect to, which must be on the region list (piactl get regions) |
| VPN_PORT | Inactive or a number | The port forward reported by the PIA client. Set automatically |

## Volumes

| Volume | Example | Function |
| :----: | --- | --- |
| /config | /opt/docker/docker-pia | The home directory of docker_user, and where configuration files will live |

## Below are the instructions for updating containers:

### Via Docker Run/Create
* Update the image: `docker pull wiorca/docker-pia`
* Stop the running container: `docker stop docker-pia`
* Delete the container: `docker rm docker-pia`
* Recreate a new container with the same docker create parameters as instructed above (if mapped correctly to a host folder, your `/config` folder and settings will be preserved)
* Start the new container: `docker start docker-pia`
* You can also remove the old dangling images: `docker image prune`

### Via Docker Compose
* Update all images: `docker-compose pull`
  * or update a single image: `docker-compose pull docker-pia`
* Let compose update all containers as necessary: `docker-compose up -d`
  * or update a single container: `docker-compose up -d docker-pia`
* You can also remove the old dangling images: `docker image prune`

### Via Watchtower auto-updater (especially useful if you don't remember the original parameters)
* Pull the latest image at its tag and replace it with the same env variables in one run:
  ```
  docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once docker-pia
  ```
* You can also remove the old dangling images: `docker image prune`

## Building locally

If you want to make local modifications to these images for development purposes or just to customize the logic:
```
git clone https://github.com/wiorca/docker-pia.git
cd docker-pia
docker build \
  --no-cache \
  --pull \
  -t wiorca/docker-pia:latest .
```
