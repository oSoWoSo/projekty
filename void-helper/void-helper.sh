#!/bin/sh

# root check
if [ "$(id -u)" != 0 ]; then
	if [ -f /usr/bin/sudo ]; then
		echo "$(tput bold)INFO: Using sudo for root operations.$(tput sgr0)"
		root="sudo"
	elif [ -f /usr/bin/doas ]; then
		echo "$(tput bold)INFO: Using doas for root operations.$(tput sgr0)"
		root="doas"
	fi
fi

# xbps install function
xinstall() {
	$root xbps-install "${@}"
}

# Install gum
if ! command -v gum >/dev/null 2>&1; then
	echo "I need gum to work! installing..."
	xinstall -S gum
fi

# Function for showing messages (green)
show_message() {
	gum style --border-foreground="00002" --border="rounded" "${1}"
}

# Function for showing info messages (yellow)
show_info() {
	gum style --border-foreground="00003" --border="rounded" "${1}"
}

# Function for asking (Choosen by default) (green)
show_prompt() {
	gum confirm --prompt.foreground="00002" --selected.background="00002" "${1}"
}

# Function for asking  (Not choosen by default) (green)
show_prompt_no() {
	gum confirm --prompt.foreground="00002" --selected.background="00002" --default=0 "${1}"
}

# Functions to show menus (green)
gum_choose() {
	header1="$1"
	shift
	gum choose --ordered --cursor.foreground="00002" --header.foreground="00002" --selected.foreground="00002" --header="${header1}" "${@}"
}

# variables
progname="Void Helper"
version="2.0.0"

# show header
show_message "$progname $version"
echo "Author: oSoWoSo (https://codeberg.org/oSoWoSo)"
echo "Contributor: Raven (https://codeberg.org/jh1r)"
echo 'under GPLv3 License'
xbps-query -v --version | sed 's/GIT: UNSET//'
gum --version

# Install recommended packages
show_prompt "Installing recommended packages?" && recommended="yes"

# Install development packages
show_prompt_no "Do you want to install packages needed for developing software?" && development="yes"

# Enable non-free repository
non_free() {
	show_prompt "Do you want to install latest NVIDIA proprietary drivers?" && \
	test "$(xbps-query -l | grep xf86-video-nouveau)" -eq 0 && \
	$root xbps-remove xf86-video-nouveau && \
	xinstall -y nvidia
}
show_prompt_no "Do you want to enable the non-free repository?" && nonfree="yes"

# Install shell
show_info "Choosing a system shell"
shell=$(gum_choose "Which shell do you want to use as default?" "Bash" "Fish" "ZSH")

# Install a terminal text editor
show_info "Choosing a terminal text editor"
editor=$(gum_choose "Which terminal text editor do you want to install?" "Helix" "Emacs" "Micro" "Vim" "Neovim" "Joe" "Nano" "None")

# Configure audio
show_info "Choosing Audio"
audio=$(gum_choose "Which audio software do you want to install?" "Pipewire" "ALSA" "PulseAudio" "None")

# Configure network management
show_info "Choosing network management"
netmngmt=$(gum_choose "Which network management software do you want to install?" "Network Manager" "dhcpcd + wpa_supplicant" "dhcpcd + IWD" "Connman" "None")

# Configure Bluetooth
show_prompt_no "Do you want to configure Bluetooth?" && bluetooth="yes"

# Configure Printing
printers() {
	show_prompt_no "Do you have a HP printer?" && \
	 show_message "Installing HPLIP" && \
	 xinstall -y hplip
	show_prompt_no "Do you have a Samsung or Xerox printer?" && \
	 show_message "Installing Splix" && \
	 xinstall -y splix
}
show_prompt_no "Do you want to install software needed for printing?" && printing="yes"

# Configure Notebook Power Saving
show_prompt_no "Do you use Void Linux on a notebook?" && notebook="yes"

# Configure NFS for sharing files
show_prompt "Do you want to install NFS for file sharing?" && sharing="yes"

# Install AM AppImage manager
show_prompt "Do you want to install AM AppImage package manager and dependencies?" && appimages="yes"

# Configure a graphical environment

gui_part() {
	xkb=$(gum_choose "Which default language do you want to set?" "English US" "German" "English UK" "French" "Italian" "Swedish" "Norwegian" "Czech")

	# Install a desktop environment
	show_prompt_no "Do you want to install a desktop environment?" && \
	 desktop=$(gum_choose "Which desktop do you want to install?" "Budgie" "Cinnamon" "GNOME" "KDE Plasma" "LXQt" "MATE" "Xfce" "Enlightenment" "Lumina" "None")

	# Install a window manager
	show_prompt "Do you want to install a window manager?" && \
	 windowmanager=$(gum_choose "Do you want to install a window manager?" "Awesome" "i3wm" "Openbox" "Fluxbox" "Bspwm" "Herbstluftwm" "IceWM" "JWM" "DWM" "Qtile" "FVWM3" "Sway [wayland]" "Wayfire [wayland]" "Hyprland [wayland]" "None")

	# Install Display Manager
	show_info "Choosing a Display Manager"
	displaymanager=$(gum_choose "Which display manager do you want to install?" "LightDM" "Emptty" "Slim" "SDDM" "GDM" "None")

	# Install Flatpak
	show_prompt_no "Do you want to install Flatpak?" && flatpak="yes"

	# Install a terminal emulator
	show_info "Choosing a terminal emulator"
	terminal=$(gum_choose "Which terminal emulator do you want to install?" "Kitty" "Alacritty" "XTerm" "LXTerminal" "Yakuake" "Sakura" "None")

	# Install a web browser
	show_info "Choosing a web browser"
	browser=$(gum_choose "Which web browser do you want to install?" "Firefox" "Firefox ESR" "Chromium" "qutebrowser" "Falkon" "Epiphany" "Badwolf" "None")

	# Install a media player
	show_info "Choosing a media player"
	mediaplayer=$(gum_choose "Which media player do you want install?" "mpv" "VLC" "Parole [Xfce]" "Totem [Gnome]" "Dragon Player [KDE]" "None")


	# Install an office suite
	show_info "Choosing an office suite"
	officesuite=$(gum_choose "Which office suite do you want to install?" "LibreOffice [GTK]" "LibreOffice [Qt]" "OnlyOffice [flatpak]" "None")

	# Install graphic design programs
	show_info "Choosing graphic design programs"
	graphic=$(gum_choose "Which graphic design programs do you want to install?" "GIMP" "Inkscape" "Krita" "GIMP + Inkscape" "Krita + Inkscape" "None")

	# Install container or virtual machine programs
	show_info "Choosing container or virtual machine programs"
	virtcnt=$(gum_choose "Which container or virtual machine program do you want to install?" "QEMU + Quickemu" "QEMU + Virt Manager" "QEMU [no GUI]" "Docker" "Kubernetes" "Docker + Kubernetes" "Linux Containers [LXC/LXD]" "None")

	# Install a backup program
	show_info "Choosing a backup program"
	backup=$(gum_choose "Which backup program do you want to install?" "Borg Backup" "Timeshift" "Deja-dup" "None")

	# Install a graphical text editor
	show_info "Choosing a graphical text editor"
	geditor=$(gum_choose "Which graphical text editor do you want to install?" "Geany" "Gedit" "Kate" "LeafPad" "Mousepad" "Code-OSS" "Notepadqq" "Bluefish" "Emacs gtk3" "Emacs x11" "Qemacs" "Vile" "Zile" "GVim" "Kakoune" "None")
}
show_prompt "Do you want to configure a graphical environment?" && guipart="yes" && gui_part

show_prompt "Install everything?" && show_info "Installing..." || exit 0
# Do installation itself
show_message "Trying to update xbps first"
xinstall -Suy xbps
show_message "Updating system"
xinstall -uy
case $recommended in
	yes )
		show_message "Installing recommended"
		xinstall -y smartmontools zstd xz bzip2 lz4 zip unzip man-db file;;
esac
case $development in
	yes )
		show_message "Installing development"
		xinstall -y autoconf automake bison m4 make libtool meson ninja optipng sassc;;
esac
case $nonfree in
	yes )
		show_message "Installing void nonfree"
		xinstall -y void-repo-nonfree && non_free;;
esac
case $shell in
	Fish )
		show_message "Installing Fish"
		xinstall -y fish-shell
		$root usermod -s /usr/bin/fish "$(id -un)";;

	ZSH )
		show_message "Installing ZSH"
		xinstall -y zsh zsh-autosuggestions zsh-syntax-highlighting
		$root usermod -s /usr/bin/zsh "$(id -un)";;

	Bash)
		show_message "Installing Bash"
		xinstall -y bash-completion
		$root usermod -s /usr/bin/bash "$(id -un)";;
esac
case $editor in
	Emacs )
		show_message "Installing Emacs NOX"
		xinstall -y emacs;;


	Micro )
		show_message "Installing Micro"
		xinstall -y micro;;


	Vim )
		show_message "Installing Vim"
		xinstall -y vim;;


	Neovim)
		show_message "Installing Neovim"
		xinstall -y neovim;;


	Joe )
		show_message "Installing Joe"
		xinstall -y joe;;


	Helix )
		show_message "Installing Helix"
		xinstall -y helix;;

	Nano )
		show_message "Installing Nano"
		xinstall -y nano;;

	None ) ;;
esac
case $audio in
	ALSA )
		show_message "Installing ALSA"
		xinstall -y alsa-utils apulse
		$root usermod -aG audio "$(id -un)";;

	PulseAudio )
		show_message "Installing PulseAudio"
		xinstall -y pulseaudio pulseaudio-utils pamixer alsa-plugins-pulseaudio
		$root usermod -aG audio "$(id -un)";;

	Pipewire )
		show_message "Installing PipeWire"
		xinstall -y pipewire wireplumber libspa-bluetooth
		$root mkdir -p /etc/pipewire/pipewire.conf.d
		$root ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
		$root ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/;;

	None ) ;;
esac
case $netmngmt in
	"Network Manager" )
		show_message "Installing Network Manager"
		xinstall -y NetworkManager;;

	"dhcpcd + wpa_supplicant" )
		show_message "Installing dhcpcd + wpa_supplicant"
		xinstall -y dhcpcd wpa_supplicant;;

	"dhcpcd + IWD" )
		show_message "Installing dhcpcd + IWD"
		xinstall -y dhcpcd iwd;;

	Connman )
		show_message "Installing Connman"
		xinstall -y connman;;

	None ) ;;
esac
case $bluetooth in
	yes )
		show_message "Installing Bluez"
		xinstall -y bluez
		$root usermod -aG bluetooth "$(id -un)"
		show_prompt "Do you want to manage Bluetooth devices graphically?" && \
		 show_message "Installing Blueman" && xinstall -y blueman;;
esac
case $printing in
	yes )
		show_message "Installing CUPS"
		xinstall -y cups cups-pk-helper cups-pdf cups-filters
		$root usermod -aG lpadmin "$(id -un)"
		printers;;
esac
case $notebook in
	yes )
		show_message "Installing TLP for power saving"
		xinstall -y tlp;;
esac
case $sharing in
	yes )
		show_message "Installing NFS support"
		xinstall nfs-utils sv-netmount;;
esac
case $appimages in
	yes )
		show_message "Installing AM"
		cd /tmp || exit
		curl -s "https://raw.githubusercontent.com/ivan-hc/AM/main/INSTALL" -o INSTALL
		chmod +x INSTALL
		$root ./INSTALL;;
esac
case $guipart in
	yes )
		show_message "Installing Xorg"
		xinstall -y xorg-minimal mesa-dri;;
esac
xkb_part() {
	lang="$1"
	cat <<EOF > /tmp/00-keyboard.conf
Section	"InputClass"
	Identifier	"keyboard"
	Option	"XkbLayout"	"$lang"
EndSection
EOF
	$root mkdir -p /etc/X11/xorg.conf.d
	$root mv /tmp/00-keyboard.conf /etc/X11/xorg.conf.d/
}
case $xkb in
	German )
		xkb_part "de";;
	"English US" )
		xkb_part "us";;
	"English UK" )
		xkb_part "gb";;
	French )
		xkb_part "fr";;
	Italian )
		xkb_part "it";;
	Swedish )
		xkb_part "se";;
	Norwegian )
		xkb_part "no";;
	Czech )
		xkb_part "cz";;
esac
case $desktop in
	Xfce )
		show_message "Installing Xfce"
		xinstall -y xfce4-appfinder xfce4-battery-plugin xfce4-clipman-plugin xfce4-cpufreq-plugin \
		 xfce4-cpugraph-plugin xfce4-dict xfce4-diskperf-plugin xfce4-fsguard-plugin xfce4-genmon-plugin \
		 xfce4-notifyd xfce4-panel xfce4-panel-appmenu xfce4-places-plugin xfce4-power-manager \
		 xfce4-pulseaudio-plugin xfce4-screensaver xfce4-screenshooter xfce4-session xfce4-settings \
		 xfce4-taskmanager xfce4-terminal xfce4-whiskermenu-plugin xfce4-xkb-plugin Thunar thunar-volman \
		 thunar-archive-plugin thunar-media-tags-plugin ristretto xarchiver mousepad xfwm4 xfdesktop \
		 zathura zathura-pdf-poppler gvfs gvfs-mtp gvfs-gphoto2 xfce-polkit parole lightdm \
		 lightdm-gtk3-greeter;;

	MATE )
		show_message "Installing MATE"
		xinstall -y mate-applets mate-backgrounds mate-calc mate-control-center mate-desktop \
		 mate-icon-theme mate-indicator-applet mate-media mate-menus mate-notification-daemon \
		 mate-panel mate-panel-appmenu mate-screensaver mate-session-manager mate-settings-daemon \
		 mate-system-monitor mate-terminal mate-themes mate-tweak mate-utils mozo pluma caja \
		 caja-image-converter caja-sendto caja-wallpaper caja-xattr-tags eom atril gvfs gvfs-mtp \
		 gvfs-gphoto2 engrampa mate-power-manager mate-polkit lightdm lightdm-gtk3-greeter;;

	GNOME )
		show_message "Installing GNOME"
		xinstall -y gnome-backgrounds gnome-calculator gnome-calendar gnome-characters \
		 gnome-console gnome-control-center gnome-disk-utility gnome-screenshot gnome-session \
		 gnome-shell gnome-system-monitor gnome-video-effects nautilus nautilus-sendto sushi gdm \
		 evince eog eog-plugins gnome-text-editor;;

	"KDE Plasma" )
		show_message "Installing KDE Plasma"
		xinstall -y plasma-desktop plasma-disks plasma-firewall plasma-nm plasma-pa \
		 plasma-systemmonitor plasma-thunderbolt plasma-wayland-protocols bluedevil breeze-gtk \
		 dolphin gwenview okular ark kde-gtk-config5 kdegraphics-thumbnailers kdeplasma-addons5 \
		 kgamma5 khelpcenter kinfocenter konsole kscreen kwalletmanager spectacle sddm-kcm sddm;;

	Budgie )
		show_message "Installing Budgie"
		xinstall -y budgie-desktop budgie-control-center budgie-desktop-view \
		 budgie-screensaver gnome-backgrounds gnome-terminal nautilus nautilus-sendto sushi \
		 lightdm lightdm-gtk3-greeter gnome-system-monitor gnome-calculator gnome-calendar \
		 gnome-characters gnome-disk-utility gedit gedit-plugins eog eog-plugins evince;;

	Cinnamon )
		show_message "Installing Cinnamon"
		xinstall -y cinnamon nemo nemo-compare nemo-fileroller nemo-image-converter \
		 nemo-preview gnome-system-monitor gnome-terminal gnome-screenshot gnome-disk-utility \
		 gnome-keyring evince gvfs gvfs-mtp gvfs-gphoto2 file-roller gedit gedit-plugins \
		 eog eog-plugins lightdm lightdm-gtk3-greeter;;

	LXQt )
		show_message "Installing LXQt"
		xinstall -y lxqt-about lxqt-admin lxqt-archiver lxqt-build-tools lxqt-config \
		 lxqt-globalkeys lxqt-openssh-askpass lxqt-panel lxqt-policykit lxqt-powermanagement \
		 lxqt-qtplugin lxqt-runner lxqt-session lxqt-sudo lxqt-themes obconf-qt openbox \
		 pcmanfm-qt lximage-qt FeatherPad qlipper qterminal lxqt-notificationd sddm;;

	Lumina )
		show_message "Installing Lumina"
		xinstall -y lumina;;

	Enlightenment )
		show_message "Installing Enlightenment"
		xinstall -y enlightenment;;

	None ) ;;
esac
case $windowmanager in
	i3wm )
		show_message "Installing i3wm"
		xinstall -y i3 i3lock i3status dunst dmenu feh Thunar thunar-volman viewnior \
		 thunar-archive-plugin thunar-media-tags-plugin xarchiver lm_sensors acpi \
		 playerctl scrot htop arandr gvfs gvfs-mtp gvfs-gphoto2 xfce4-taskmanager;;

	Openbox )
		show_message "Installing Openbox"
		xinstall -y openbox obconf lxappearance dunst feh arandr pcmanfm gvfs \
		 gvfs-mtp gvfs-gphoto2 lxtask scrot htop xarchiver viewnior;;

	Fluxbox )
		show_message "Installing Fluxbox"
		xinstall -y fluxbox dunst feh arandr Thunar thunar-volman \
		 thunar-archive-plugin thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 \
		 scrot htop xarchiver viewnior;;

	Bspwm )
		show_message "Installing Bspwm"
		xinstall -y bspwm sxhkd dunst feh dmenu arandr Thunar thunar-volman \
		 thunar-archive-plugin thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 \
		 scrot htop xarchiver viewnior;;

	Herbstluftwm )
		show_message "Installing Herbstluftwm"
		xinstall -y herbstluftwm dunst feh dmenu arandr Thunar thunar-volman \
		 thunar-archive-plugin thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 \
		 scrot htop xarchiver viewnior;;

	IceWM )
		show_message "Installing IceWM"
		xinstall -y icewm dunst feh dmenu arandr Thunar thunar-volman \
		 thunar-archive-plugin thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 \
		 scrot htop xarchiver viewnior;;

	Awesome )
		show_message "Installing Awesome"
		xinstall -y awesome vicious dunst feh arandr Thunar thunar-volman \
		 thunar-archive-plugin thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 \
		 scrot htop xarchiver viewnior;;

	JWM )
		show_message "Installing JWM"
		xinstall -y jwm dunst feh dmenu arandr Thunar thunar-volman \
		 thunar-archive-plugin thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 \
		 scrot htop xarchiver viewnior;;

	DWM )
		show_message "Installing DWM"
		xinstall -y dwm dunst feh dmenu arandr Thunar thunar-volman \
		 thunar-archive-plugin thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 \
		 scrot htop xarchiver viewnior;;

	Qtile )
		show_message "Installing Qtile"
		xinstall -y python3 python3-pip python3-setuptools python3-wheel \
		 python3-virtualenv-clone python3-dbus python3-gobject pango pango-devel \
		 libffi-devel xcb-util-cursor gdk-pixbuf feh arandr Thunar thunar-volman \
		 thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 scrot htop xarchiver \
		 thunar-archive-plugin viewnior
		pip install qtile;;

	FVWM3 )
		how_message "Installing FVWM3"
		xinstall -y fvwm3 feh xfce4-terminal arandr Thunar thunar-volman gvfs htop \
		 thunar-archive-plugin thunar-media-tags-plugin gvfs gvfs-mtp gvfs-gphoto2 \
		 mousepad scrot htop xarchiver viewnior;;

	"Sway [wayland]" )
		show_message "Installing Sway"
		xinstall -y sway swaybg swayidle swaylock azote grimshot \
		 Waybar gvfs gvfs-mtp gvfs-gphoto2 htop wofi wayclip;;

	"Wayfire [wayland]" )
		show_message "Installing Wayfire"
		xinstall -y wayfire grim gvfs gvfs-mtp gvfs-gphoto2 htop wofi \
		 azote wayclip shotman;;

	"Hyprland [wayland]" )
		show_message "Installing Hyprland"
		echo 'repository=https://github.com/Makrennel/hyprland-void/tree/repository-x86_64-glibc' > /tmp/hyprland-repo.conf
		$root mv /tmp/hyprland-repo.conf /etc/xbps.d/
		xi hyprland;;

	None) ;;
esac
case $displaymanager in
	LightDM )
		show_message "Installing LightDM"
		xinstall -y lightdm lightdm-gtk3-greeter lightdm-gtk-greeter-settings;;

	Emptty )
		show_message "Installing Emptty"
		xinstall -y emptty;;

	Slim )
		show_message "Installing Slim"
		xinstall -y slim slim-void-theme;;

	SDDM )
		show_message "Installing SDDM"
		xinstall -y sddm;;

	GDM )
		show_message "Installing GDM"
		xinstall -y gdm gdm settings;;

	None ) ;;
esac
case $flatpak in
	yes )
	show_message "Installing Flatpak"
	xinstall -y flatpak;;
esac
case $terminal in
	Alacritty )
		show_message "Installing Alacritty"
		xinstall -y alacritty alacritty-terminfo;;

	XTerm )
		show_message "Installing XTerm"
		xinstall -y xterm;;

	LXTerminal )
		show_message "Installing LXTerminal"
		xinstall -y lxterminal;;

	Yakuake )
		show_message "Installing Yakuake"
		xinstall -y yakuake;;

	Sakura )
		show_message "Installing Sakura"
		xinstall -y sakura;;

	Kitty )
		show_message "Installing Kitty"
		xinstall -y kitty kitty-terminfo;;

	None ) ;;
esac
case $browser in
	Firefox )
		show_message "Installing Firefox"
		xinstall -y firefox firefox-i18n-en-US firefox-i18n-de;;

	"Firefox ESR" )
		show_message "Installing Firefox ESR"
		xinstall -y firefox-esr firefox-esr-i18n-en-US firefox-esr-i18n-de;;

	Chromium )
		show_message "Installing Chromium"
		xinstall -y chromium;;

	qutebrowser )
		show_message "Installing Qutebrowser"
		xinstall -y qutebrowser;;

	Falkon )
		show_message "Installing Falkon"
		xinstall -y falkon;;

	Epiphany )
		show_message "Installing Epiphany"
		xinstall -y epiphany;;

	Badwolf )
		show_message "Installing Badwolf"
		xinstall -y badwolf;;

	None ) ;;
esac
case $mediaplayer in
	mpv )
		show_message "Installing mpv"
		xinstall -y mpv;;

	VLC )
		show_message "Installing VLC Media Player"
		xinstall -y vlc;;

	"Parole [Xfce]" )
		show_message "Installing Parole"
		xinstall -y parole;;

	"Totem [Gnome]" )
		show_message "Installing Totem"
		xinstall -y totem;;

	"Dragon Player [KDE]" )
		show_message "Installing Dragon Player"
		xinstall -y dragon-player;;

	None ) ;;
esac
case $officesuite in
	"LibreOffice [GTK]" )
		show_message "Installing LibreOffice (GTK)"
		xinstall -y libreoffice-writer libreoffice-calc libreoffice-impress \
		 libreoffice-draw libreoffice-gnome;;

	"LibreOffice [Qt]" )
		show_message "Installing LibreOffice (Qt)"
		xinstall -y libreoffice-writer libreoffice-calc libreoffice-impress \
		 libreoffice-draw libreoffice-kde;;

	"OnlyOffice [flatpak]" )
		show_message "Installing OnlyOffice"
		$root flatpak install org.onlyoffice.desktopeditors;;
esac
case $graphic in
	GIMP )
		show_message "Installing GIMP"
		xinstall -y gimp;;

	Inkscape )
		show_message "Installing Inkscape"
		xinstall -y inkscape;;

	Krita )
		show_message "Installing Krita"
		xinstall -y krita;;

	"GIMP + Inkscape" )
		show_message "Installing GIMP and Inkscape"
		xinstall -y gimp inkscape;;

	"Krita + Inkscape" )
		show_message "Installing Krita + Inkscape"
		xinstall -y krita inkscape;;

	None ) ;;
esac
case $virtcnt in
	"QEMU + Virt Manager" )
		show_message "Installing QEMU + Virt Manager"
		xinstall -y qemu libvirt virt-manager virt-manager-tools;;

	"QEMU + Quickemu" )
		show_message "Installing QEMU + Quickemu"
		xinstall -y qemu gawk grep glxinfo jq pciutils procps-ng python3 cdrtools usbutils util-linux sed socat spicy swtpm xdg-user-dirs xrandr zsync unzip
		curl -s "https://raw.githubusercontent.com/quickemu-project/quickemu/refs/heads/master/quickget" > /tmp/quickget
		curl -s "https://raw.githubusercontent.com/quickemu-project/quickemu/refs/heads/master/quickemu" > /tmp/quickemu
		curl -s "https://raw.githubusercontent.com/quickemu-project/quickemu/refs/heads/master/chunkcheck" > /tmp/chunkcheck
		curl -s "https://raw.githubusercontent.com/quickemu-project/quickemu/refs/heads/master/quickreport" > /tmp/quickreport
		$root mkdir -p /opt/quickemu
		cd /tmp/ || exit
		$root mv quickget /opt/quickemu/quickget
		$root mv quickemu /opt/quickemu/quickemu
		$root mv chunkcheck /opt/quickemu/chunkcheck
		$root mv quickreport /opt/quickemu/quickreport
		cd /opt/quickemu/ && $root chmod a+x quickget quickemu chunkcheck quickreport;;

	"QEMU [no GUI]" )
		show_message "Installing QEMU (without GUI)"
		xinstall -y qemu libvirt;;

	Docker )
		show_message "Installing Docker"
		xinstall -y docker docker-cli;;

	Kubernetes )
		show_message "Installing Kubernetes"
		xinstall -y kubernetes;;

	"Docker + Kubernetes" )
		show_message "Installing Docker and Kubernetes"
		xinstall -y docker docker-cli kubernetes;;

	"Linux Containers [LXC/LXD]" )
		show_message "Installing Linux Containers (LXC/LXD)"
		xinstall -y lxc lxd;;

	None ) ;;
esac
case $backup in
	"Borg Backup" )
		show_message "Installing Borg Backup"
		xinstall -y borg;;

	Timeshift )
		show_message "Installing Timeshift"
		xinstall -y timeshift;;

	Deja-dup )
		show_message "Installing Deja-dup"
		xinstall -y deja-dup;;

	None ) ;;
esac
case $geditor in
	Geany )
		show_message "Installing Geany"
		xinstall -y geany geany-plugins geany-plugins-extra;;

	Gedit )
		show_message "Installing Gedit"
		xinstall -y gedit gedit-plugins;;

	Kate )
		show_message "Installing Kate"
		xinstall -y kate5;;

	LeafPad )
		show_message "Installing LeafPad"
		xinstall -y leafpad;;

	Mousepad )
		show_message "Installing Mousepad"
		xinstall -y mousepad;;

	Code-OSS )
		show_message "Installing VSCodium"
		xinstall -y vscode;;

	Notepadqq )
		show_message "Installing Notepadqq"
		xinstall -y notepadqq;;

	Bluefish )
		show_message "Installing Bluefish"
		xinstall -y bluefish;;

	"Emacs gtk3" )
		show_message "Installing the GTK3 version of Emacs"
		xinstall -y emacs-gtk3;;

	"Emacs x11" )
		show_message "Installing the X11 version of Emacs"
		xinstall -y emacs-x11;;

	Qemacs )
		show_message "Installing QEmacs"
		xinstall -y qemacs;;

	Vile )
		show_message "Installing Vile"
		xinstall -y vile;;

	Zile )
		show_message "Installing Zile"
		xinstall -y zile;;

	GVim )
		show_message "Installing GVim"
		xinstall -y gvim;;

	Kakoune )
		show_message "Installing Kakoune"
		xinstall -y kakoune;;

	None ) ;;
esac
# Enable or disable services
manage_services() {
	services=$(gum_choose "Which service you want to autostart?" --height=23 --no-limit $(diff -r /etc/sv/ /var/service/ | grep "etc/sv" | cut -d' ' -f4))
	for service in $services; do
		show_message "Enabling ${service} service"
		$root ln -sv "/etc/sv/${service}" /var/service/
	done

	removeServices=$(gum_choose "Which service you want to REMOVE?" --height=23 --no-limit $(ls /var/service/))
	for service in $removeServices; do
		show_message "Disabling ${service} service"
		$root rm "/var/service/${service}"
	done
}
show_prompt "Manage services?" && manage_services

show_message "CONFIGURATION FINISHED. ENJOY VOID LINUX :)
PS: If you spotted any bug, please contact me to get things right"
