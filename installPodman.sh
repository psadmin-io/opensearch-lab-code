#! /bin/bash

# Install and configure for rootless podman
sudo dnf install podman podman-plugins cr
sudo podman system info --runtime=crun

mkdir -p $HOME/.config/containers/
tee $HOME/.config/containers/storage.conf << EOF
[storage]
driver    = "overlay"
[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

# Update OS Params for Opensearch
echo "user.max_user_namespaces=28633" | sudo tee -a /etc/sysctl.d/userns.conf
sudo sysctl -p /etc/sysctl.d/userns.conf
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

# Add docker.io to Registry 
echo 'unqualified-search-registries = ["docker.io"]' | sudo tee -a /etc/containers/registries.conf

# Enable linger for opc user processes
sudo loginctl enable-linger opc

# Configure profile for podman socket and aliases
echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" >> /home/opc/.bash_profile
echo "export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock" >> /home/opc/.bash_profile
echo "alias podman=\"sudo /usr/bin/podman\"" >> /home/opc/.bash_profile
echo "alias docker=\"sudo /usr/bin/podman\"" >> /home/opc/.bash_profile
source ~/.bash_profile

# Start podman
systemctl --user enable podman.socket
systemctl --user start podman.socket
systemctl --user status podman.socket
curl -H "Content-Type: application/json" --unix-socket /run/user/$UID/podman/podman.sock http://localhost/_ping