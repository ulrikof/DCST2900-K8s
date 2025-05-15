#!/bin/bash

# Update package list
sudo apt update

# Install HAProxy
sudo apt install -y haproxy

# Replace the default config with your the template in this folder
sudo cp haproxy.cfg /etc/haproxy/haproxy.cfg

# Validate the new configuration
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Enable HAProxy to start on boot
sudo systemctl enable haproxy

# Start HAProxy service
sudo systemctl start haproxy

# Check HAProxy status
sudo systemctl status haproxy
