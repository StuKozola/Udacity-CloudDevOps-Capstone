#!/usr/bin/env bash

# sourced from https://stackoverflow.com/questions/19339248/append-line-to-etc-hosts-file-with-shell-script/19339320

# path to hosts file\
host_file="/etc/hosts"

# insert/update hosts entry
ip_address="$1"
host_name="$2"
alias1="$3"
alias2="$4"

# find existing instances in the host file and save the line numbers
matches_in_hosts="$(grep -n $host_name $host_file| cut -f1 -d:)"
host_entry="${ip_address} ${host_name} ${alias1} ${alias2}"
echo $host_entry

echo "Please enter your password if requested."

if [ ! -z "$matches_in_hosts" ]
then
    echo "Updating existing hosts entry."
    # iterate over the line numbers on which matches were found
    while read -r line_number; do
        # replace the text of each line with the desired host entry
        sudo sed "${line_number} s/.*/${host_entry} /" $host_file
    done <<< "$matches_in_hosts"
else
    echo "Adding new hosts entry."
    echo "$host_entry" | sudo tee -a $host_file > /dev/null
fi