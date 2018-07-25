#!/bin/bash

### ideas
# gtfo-bins ideas
# interesting files are world-readable
# ssh-agent / gpg-agent stuff?
# places current user can write. esp under /etc
# Ignore
# -- common files with setuid
# -- things in /etc that come by default?
# -- config files that haven't been modified from default?


BOLD="\033[1m"
RED="\033[91m"
GREEN="\033[92m"
ORANGE="\033[93m"
BLUE="\033[94m"
HEADER="\033[95m"
END="\033[0m"


usage() {
  echo "Usage: "$0" [OPTIONS]
    -a, --all       equivalent to -b -f -n -u
    -b, --basic     Get basic OS info
    -c, --color     Add color to program output
    -f, --files     Look for interesting files
    -n, --network   Get network info
    -u, --user      Look for interesting info in user's home dirs"
}


# print section dividers for different types of content
print_section() {
  if [[ "$COLOR" == true ]]; then
    printf "$BLUE### $1 ### $END \n"
  else
    printf "### $1 ### \n"
  fi
}


# print command we're about to run
print_cmd() {
  if [[ "$COLOR" == true ]]; then
    printf "$BOLD# $1 $END \n"
  else
    printf "# $1 \n" 
  fi
}


run() {
  print_cmd "$1"
  $1
  ret="$?"
  printf "\n"
  return "$ret"
}


get_basic_info() {
  # chkconfig ?
  # Services that start at boot?
  # external auth via grep '^+:' /etc/passwd
  # -- password hashes
  # -- users w/ no password
  # /etc/nsswitch.conf lines for nis & ldap
  # -- ^passwd line contains nis or ldap
  print_section "OS basics"
  run "hostname"
  run "cat /etc/*release"
  run "cat /proc/version"
  run "cat /etc/passwd"
  run "cat /etc/fstab"
  run "mount"
  run "ps -ef"
  run "w"
  run "last"
  run "env"
  run "crontab -l"
  run "ls -la /var/spool/cron"
  run "ls -la /etc/cron.*"

  if [[ "$OS" == "debian" ]]; then
    run "uname -a"
    run "dpkg -l"
  elif [[ "$OS" == "redhat" ]]; then 
    run "rpm -q kernel"
    run "rpm -qa"
  fi
}

get_network_info() {
  # /etc/sysconfig/network - redhat?
  print_section "Network info"
  run "ifconfig -a" || run "ip a"
  run "cat /etc/resolv.conf"
  run "cat /etc/networks"
  run "lsof -i"
  run "netstat -tulpn"
  run "iptables -L"
}


get_user_files() {
  # .ssh
  print_section "User files"
  for user in $(ls /home)
  do
    run "ls -la /home/$user"
  done
}


get_interesting_files() {
  # /etc/sudoers
  # /etc/shadow
  print_section "File permissions"
  run "find / -perm -u=s -o -perm -g=s -type f 2>/dev/null"
  run "find / -perm -o+w -not -type l 2>/dev/null"
}


# Start main
COLOR=false
BASIC=false
NETWORK=false
USER=false
FILES=false
ALL=false

# Parse arguments
while [[ "$#" -gt 0 ]]
  do
  arg="$1"

  case "$arg" in
    -c|--color)
    COLOR=true
    shift
    ;;
    -b|--basic)
    BASIC=true
    shift
    ;;
    -n|--network)
    NETWORK=true
    shift
    ;;
    -u|--user)
    USER=true
    shift
    ;;
    -f|--files)
    FILES=true
    shift
    ;;
    -a|--all)
    ALL=true
    shift
    ;;
    *)
    echo "Unknown option: $1"
    usage
    exit 1
    ;;
  esac
done

# Guess flavor of Linux
if [[ -f /etc/lsb-release ]] || [[ -f /etc/os-release ]]; then
  OS="debian"
elif [[ -f /etc/redhat-release ]]; then
  OS="redhat"
else
  echo "[-] WARNING - could not reliably determine OS"
  OS="debian"
fi

if [[ "$ALL" == true ]]; then
  get_basic_info
  get_network_info
  get_user_files
  get_interesting_files
else
  if [[ "$BASIC" == true ]]; then get_basic_info; fi
  if [[ "$NETWORK" == true ]]; then get_network_info; fi
  if [[ "$USER" == true ]]; then get_user_files; fi
  if [[ "$FILES" == true ]]; then get_interesting_files; fi
fi
