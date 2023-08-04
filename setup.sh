#!/bin/bash

# Install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd
rm -rf yay

# Install and configure window manager/desktop environment
sudo pacman -S --noconfirm xorg xf86-video-amdgpu arandr bspwm sxhkd polybar

install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc

mkdir ~/.config/polybar/
cp /usr/share/doc/polybar/config ~/.config/polybar/config
echo "#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar, using default config location ~/.config/polybar/config
polybar mybar &

echo "Polybar launched..." " > ~/.config/polybar/launch.sh
echo "~/.config/polybar/launch.sh" >> ~/.config/bspwm/bspwmrc