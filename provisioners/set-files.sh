#! /bin/bash

set -e;

# Create the dreambox directory.
[[ ! -d /usr/local/dreambox ]] && mkdir /usr/local/dreambox;

# Copy support files into place.
rsync -av --exclude='motd' --exclude='preseed' /tmp/files/* /usr/local/dreambox/;

# Remove existing motd and set up ours.
rm -f /etc/update-motd.d/*

# Move MOTD files into place.
mv -f /tmp/files/motd/* /etc/update-motd.d/;

# Set MOTD files as executable.
chmod +x /etc/update-motd.d/*;

# This helps make sure the message is displayed correctly on the first login.
sed -i -r 's/(motd=\/run\/motd\.dynamic)( noupdate)/\1/' /etc/pam.d/login;
sed -i -r 's/(motd=\/run\/motd\.dynamic)( noupdate)/\1/' /etc/pam.d/sshd;

exit $?;
