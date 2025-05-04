#!/usr/bin/env bash

# Get dependent parameters
source "$(dirname "$(readlink -f "${0}")")/get_param.sh"

# 確保 Terminator 設定存在於主機，供 container 掛載使用（可選）
HOST_TERMINATOR_CONFIG_DIR="${HOME}/.config/terminator"
if [ ! -f "${HOST_TERMINATOR_CONFIG_DIR}/config" ]; then
    mkdir -p "${HOST_TERMINATOR_CONFIG_DIR}"
    cat << EOF > "${HOST_TERMINATOR_CONFIG_DIR}/config"
[global_config]
[keybindings]
[profiles]
  [[default]]
    use_system_font = False
    font = Monospace 10
[layouts]
  [[default]]
    [[[child1]]]
      type = Terminal
      parent = window0
    [[[window0]]]
      type = Window
      parent = ""
[plugins]
EOF
fi


docker run --rm \
    --privileged \
    --network=host \
    --ipc=host \
    ${GPU_FLAG} \
    -v /tmp/.Xauthority:/home/"${user}"/.Xauthority \
    -e XAUTHORITY=/home/"${user}"/.Xauthority \
    -e DISPLAY="${DISPLAY}" \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /dev:/dev \
    -v /run/user/$UID:/run/user/$UID \
    -e DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus" \
    -v "${WS_PATH}":/home/"${user}"/work \
    --user $(id -u):$(id -g) \
    -it --name "${CONTAINER}" "${DOCKER_HUB_USER}"/"${IMAGE}"

