#!/usr/bin/env bash

# sourced from https://gist.github.com/irazasyed/a7b0a079e7727a4315b9
# usage: manage-etc-hosts [add|remove] <hostname> "<domain_names>"

# Path to your hosts file
hostsFile="hosts" #"/etc/hosts"

# Default IP address for host
ip="0.0.0.0"

# Hostname to add/remove.
hostname="$2"

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

if [ -z "$1" ] || [ -z "$2" ]; then
   die "Exiting... invalid arguments";
fi

remove() {
    if [ -n "$(grep -w "$hostname$" /etc/hosts)" ]; then
        echo "$hostname found in $hostsFile. Removing now...";
        try sudo sed -ie "/[[:space:]]$hostname/d" "$hostsFile";
    else
        yell "$hostname was not found in $hostsFile";
    fi
}

add() {
    if [ -n "$(grep -P "[[:space:]]$hostname" /etc/hosts)" ]; then
        yell "$hostname, already exists: $(grep $hostname $hostsFile)";
    else
        echo "Adding $hostname to $hostsFile...";
        try printf "%s\t%s\n" "$ip" "$hostname" | sudo tee -a "$hostsFile" > /dev/null;

        if [ -n "$(grep $hostname /etc/hosts)" ]; then
            echo "$hostname was added succesfully:";
            echo "$(grep $hostname /etc/hosts)";
        else
            die "Failed to add $hostname";
        fi
    fi
}

$@