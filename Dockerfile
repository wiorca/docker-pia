
# Based on Ubuntu 20.04 LTS
FROM ubuntu:20.04

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=0.0.12

# Labels
LABEL com.wiorca.build-date=$BUILD_DATE \
      com.wiorca.vcs-url="https://github.com/wiorca/docker-pia.git" \
      com.wiorca.vcs-ref=$VCS_REF \
      com.wiorca.schema-version=$VERSION

# The volume for the docker_user home directory, and where configuration files should be stored.
VOLUME [ "/config" ]

# Some environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Toronto \
    PUID=1000 \
    PGID=1000 \
    PIA_USERNAME=username \
    PIA_PASSWORD=password \
    PIA_DEBUG_LOGGING=false \
    PIA_PROTOCOL=openvpn \
    PIA_PORT_FORWARD=true \
    PIA_LOCATION=auto

# Update ubuntu container, and install the basics, Add windscribe ppa, Install windscribe, and some to be removed utilities
RUN apt -y update && apt -y dist-upgrade && apt install -y gnupg apt-utils ca-certificates expect iptables iputils-ping net-tools iputils-tracepath curl \
    libnl-3-200 libnl-route-3-200 libglib2.0-0 iproute2 && \
    echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections && \
    apt -y autoremove && apt -y clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add in the docker user
RUN groupadd -r docker_group  && useradd -r -d /config -g docker_group docker_user

# Add in scripts for health check and start-up
ADD scripts /opt/scripts/
ADD install.sh /install.sh

# Install PIA
RUN curl -L $( curl -s https://www.privateinternetaccess.com/installer/download_installer_linux_beta | grep installers | cut -d \" -f 2 | cut -d \= -f 2 ) > /installer.bin && \
    chmod o+rwx /installer.bin && /installer.bin --quiet --accept --noprogress --nox11 --noexec --keep --target /pia-installer && \
    cp /install.sh /pia-installer/install.sh && /pia-installer/install.sh --skip-service && \
    rm -rf /pia-installer /installer.bin /install.sh

# Enable the health check for the VPN and app
HEALTHCHECK --interval=5m --timeout=60s \
  CMD /opt/scripts/health-check.sh || exit 1

# Run the container
CMD [ "/bin/bash", "/opt/scripts/vpn-startup.sh" ]
