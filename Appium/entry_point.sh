#!/bin/bash

NODE_CONFIG_JSON="/root/nodeconfig.json"
DEFAULT_CAPABILITIES_JSON="/root/defaultcapabilities.json"
APPIUM_LOG="/var/log/appium.log"
CMD="xvfb-run appium --log $APPIUM_LOG"
SSH_USER=ssh-forward-user
SSH_USER_PASSWORD=docker

if [ ! -z "${SALT_MASTER}" ]; then
    echo "[INIT] ENV SALT_MASTER it not empty, salt-minion will be prepared"
    echo "master: ${SALT_MASTER}" >> /etc/salt/minion
    salt-minion &
    echo "[INIT] salt-minion is running..."
fi

if [ "$ATD" = true ]; then
    echo "[INIT] Starting ATD..."
    java -jar /root/RemoteAppiumManager.jar -DPort=4567 &
    echo "[INIT] ATD is running..."
fi

if [ "$REMOTE_ADB" = true ]; then
    /root/wireless_connect.sh
fi

if [ "$CONNECT_TO_GRID" = true ]; then
    if [ "$CUSTOM_NODE_CONFIG" != true ]; then
        /root/generate_config.sh $NODE_CONFIG_JSON
    fi
    CMD+=" --nodeconfig $NODE_CONFIG_JSON"
fi

if [ "$DEFAULT_CAPABILITIES" = true ]; then
    CMD+=" --default-capabilities $DEFAULT_CAPABILITIES_JSON"
fi

if [ "$RELAXED_SECURITY" = true ]; then
    CMD+=" --relaxed-security"
fi

if [ "$CHROMEDRIVER_AUTODOWNLOAD" = true ]; then
    CMD+=" --allow-insecure chromedriver_autodownload"
fi

adb forward tcp:$ALT_UNITY_PORT tcp:$ALT_UNITY_PORT
pkill -x xvfb-run
rm -rf /tmp/.X99-lock

echo "setting up local port forwarding"
useradd -p "$(openssl passwd -1 $SSH_USER_PASSWORD)" -rm -d /home/$SSH_USER -g root $SSH_USER
/etc/init.d/ssh restart
sshpass -p $SSH_USER_PASSWORD ssh -o stricthostkeychecking=no -g -L $APPIUM_HOST:$ALT_UNITY_PORT:0.0.0.0:$ALT_UNITY_PORT -N -f $SSH_USER@localhost

$CMD
