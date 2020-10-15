#! /bin/bash

# Verify pia daemon is running

PIAD=$(pgrep pia-daemon | wc -l )
if [[ ${PIAD} -ne 1 ]]
then
	echo "PIA process not running"
	exit 1
fi

# Verify pia daemon is running

PIAD=$(pgrep pia-wireguard-g | wc -l )
if [[ ${PIAD} -ne 1 ]]
then
	PIAD=$(pgrep pia-openvpn | wc -l )
	if [[ ${PIAD} -ne 1 ]]
	then
		echo "PIA wireguard or openvpn not running"
		exit 1
	fi
fi

# Verify windscribe service is happy

/opt/scripts/vpn-health-check.expect

if [ ! $? -eq 0 ]; then
    exit 1;
fi

# Veryify we can ping out

ping -c 1 google.com
STATUS=$?
if [[ ${STATUS} -ne 0 ]]
then
    echo "Network is down"
    exit 1
fi

echo "Network is up"

# Check the app health

/opt/scripts/app-health-check.sh

if [ ! $? -eq 0 ]; then
    exit 1;
fi

exit 0

