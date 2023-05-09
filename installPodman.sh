#! /bin/bash

function echoinfo() {
  local GC="\033[1;32m"
  local EC="\033[0m"
  printf "${GC} ☆  INFO${EC}: %s${GC}\n${EC}" "$@";
}

function echoerror() {
  local RC="\033[1;31m"
  local EC="\033[0m"
  printf "${RC} ✖  ERROR${EC}: %s\n${EC}" "$@" 1>&2;
}

echoinfo "Install and configure for rootless podman"
sudo dnf install podman podman-plugins 1>/dev/null 
sudo podman system info --runtime=crun 1>/dev/null 

mkdir -p $HOME/.config/containers/
tee $HOME/.config/containers/storage.conf 1>/dev/null << EOF
[storage]
driver    = "overlay"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF
sleep 2

echoinfo "Update OS Params for Opensearch"
echo "user.max_user_namespaces=28633" | sudo tee -a /etc/sysctl.d/userns.conf 1>/dev/null
sudo sysctl -p /etc/sysctl.d/userns.conf 1>/dev/null
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf 1>/dev/null
sudo sysctl -p /etc/sysctl.conf 1>/dev/null
sleep 2

echoinfo "Add docker.io to Registry"
echo 'unqualified-search-registries = ["docker.io"]' | sudo tee -a /etc/containers/registries.conf 1>/dev/null
sleep 2

echoinfo "Enable linger for opc user processes"
sudo loginctl enable-linger "$(whoami)"
sleep 2

echoinfo "Configure profile for podman socket and aliases"
echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" | tee -a $HOME/.bash_profile 1>/dev/null
echo "export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock" | tee -a $HOME/.bash_profile 1>/dev/null
echo "alias podman=\"sudo /usr/bin/podman\"" | tee -a $HOME/.bash_profile 1>/dev/null
echo "alias docker=\"sudo /usr/bin/podman\"" | tee -a $HOME/.bash_profile 1>/dev/null
source $HOME/.bash_profile 1>/dev/null
sleep 2

echoinfo "Start podman"
systemctl --user enable podman.socket
systemctl --user start podman.socket
sleep 2

echoinfo "Test if podman is running"
status=$(curl -s -H "Content-Type: application/json" --unix-socket /run/user/$UID/podman/podman.sock http://localhost/_ping)
case $status in
  'OK' )
    echoinfo "Podman is running"
    ;;
  * )
    echoerror "Podman is not running"
    ;;
esac