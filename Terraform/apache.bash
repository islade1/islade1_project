#!/bin/bash
sudo apt update
sudo apt install apache2
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw allow 'Apache'
sudo systemctl status apache2