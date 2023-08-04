#!/bin/bash

# Set new user and privileges
useradd -m -s /bin/bash adriana
passwd adriana
pacman -S --noconfirm base-devel reflector