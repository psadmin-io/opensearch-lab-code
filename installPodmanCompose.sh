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

echoinfo "Install Podman-Compose"
sudo pip3 install podman-compose > /dev/null 2>&1
sleep 2

echoinfo "Configure profile for Podman-Compose aliases"
echo 'alias pc="/usr/local/bin/podman-compose"' | tee -a ~/.bash_profile 1>/dev/null
source $HOME/.bash_profile 1>/dev/null
sleep 2
