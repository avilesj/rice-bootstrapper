#/bin/bash
# Rice
RICE_CONFIG_DIR="$HOME/.config/rice"
REPO_DIR="$HOME/.config/rice/repositories"
RICE_CONFIG_FILE="$RICE_CONFIG_DIR/rice.conf"
#Git repo
GIT_REPO="https://github.com/pavilesjose"
#Backups
BK_CONFIG_FOLDER_WHITELIST=("compton.conf" "wall.png")
BK_HOME_FOLDER_WHITELIST=(".emacs" ".xinitrc" ".env")
BK_SCRIPTS=("$HOME/.config/scripts/")
######## Script
PACKAGE_LIST="pulseaudio pulsemixer network-manager build-essential vim xorg imagemagick docker docker.io alsa-utils curl firefox libgif-dev libgnutls28-dev libgraphicsmagick++1-dev libgtk-3-dev libjpeg-dev libmagick++-6-headers libmagick++-dev libncurses5-dev libpng-dev libtiff5-dev libxpm-dev ssh xorg-dev zsh tmux xinit htop ttf-dejavu feh fonts-font-awesome software-properties-common ffmpeg libnotify-bin sxiv xcape"
# DWM
DWM_PACKAGE_LIST="compton"
DWM_COMPONENT_LIST=("dmenu" "st" "slstatus" "dwm")
# I3
I3_PACKAGE_LIST="i3 build-essential git cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev i3-wm libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev rxvt clipit"

install_polybar() {
     git clone --recursive https://github.com/polybar/polybar /tmp/polybar
     cd /tmp/polybar
     mkdir build
     cd build
     cmake ..
     make -j$(nproc)
     sudo make install
     make userconfig
     cd $HOME
}

backup() {
    for i in "${BK_CONFIG_FOLDER_WHITELIST[@]}"
    do
        echo "Copying $i to $$REPO_DIR/dotfiles/.config ..."
        cp -R $i $REPO_DIR/dotfiles/.config
    done
    
    for i in "${BK_HOME_FOLDER_WHITELIST[@]}"
    do
        echo "Copying $i to $REPO_DIR/dotfiles ..."
        cp -R $i $REPO_DIR/dotfiles/
    done

    for i in "${BK_SCRIPTS[@]}"
    do
        echo "Copying $i to $REPO_DIR/scripts ..."
        cp -R $i $REPO_DIR/scripts
    done    
}
print_install_formatted() {
    echo "INSTALLING -> $1...."
}
install_scripts() {
    cd $REPO_DIR
    git clone "$GIT_REPO/scripts"
    mkdir -p $BK_SCRIPTS
    cp scripts/* -r . $BK_SCRIPTS
    cd -
}

install_dotfiles() {
    cd $REPO_DIR
    git clone "$GIT_REPO/dotfiles"
    cp -r dotfiles/* $HOME
    cd -
}

install_oh_my_zsh() {
    cd $HOME
    git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
    sudo chsh $USER -s $(which zsh)
    echo "source $HOME/.env" >> $HOME/.zshrc
    echo "source $HOME/.work" >> $HOME/.zshrc
    touch .env
    touch .work
    cd -
}
install_desktop_hotfix() {
    cd $HOME
    if test -f "asound.conf"; then
        echo "Hotfix file found"
        sudo cp asound.conf /etc/
        echo "AUDIO_HOTFIX=true" >> $RICE_CONFIG_FILE
    else
        echo "No hotfix file found. Moving on..."
    fi

    cd -
    
}

install_thinkpad_brightness() {
    FILE=/usr/share/X11/xorg.conf.d/20-intel.conf
    touch $FILE &&
    cat > $FILE <<- EOM
Section "Device"
	Identifier  "card0"
	Driver      "intel"
	Option      "SwapBuffersWait" "0"
	Option      "Backlight"  "intel_backlight"
	Option      "DRI"    "3"
	BusID       "PCI:0:2:0"
EndSection
EOM
    echo "" &&
    echo "THINKPAD_BRIGHTNESS_HOTFIX=true" >> $RICE_CONFIG_FILE
}

install_oh_my_tmux() {
    cd $HOME
    if test -f ".tmux.conf.local"; then
        echo "Oh My Tmux already installed"
    else
        git clone https://github.com/gpakosz/.tmux.git
        ln -s -f .tmux/.tmux.conf
        cp .tmux/.tmux.conf.local .
    fi

    cd -
}
install_yarn() {
    if dpkg --list | grep yarn; then
        echo Yarn already installed
    else
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
        sudo apt update && sudo apt install --no-install-recommends yarn -y
    fi
}

install_additional_fonts() {
    if fc-list | grep file-icons; then
        echo Additional fonts already installed
    else
        FONT_LIST=("all-the-icons.ttf" "file-icons.ttf" "material-design-icons.ttf" "octicons.ttf" "weathericons.ttf")
        mkdir $HOME/.fonts
        cd /tmp
        git clone "https://github.com/domtronn/all-the-icons.el.git"
        cd all-the-icons.el/fonts
        for i in "${FONT_LIST[@]}"
        do
            echo "Copying $i to $HOME/.fonts..."
            cp $i $HOME/.fonts
        done
        fc-cache -f
    fi
}

install_packages() {
    sudo apt install $PACKAGE_LIST -y
}

install_vertical_scrolling() {
    VS_INPUT_FILE=/usr/share/X11/xorg.conf.d/40-libinput.conf
    grep "NaturalScrolling" ||
    VS_LINE_NUMBER=$(awk "/Identifier \"libinput touchpad catchall\"/ {f = 1; next} f && /MatchDevicePath/ { print NR+1; f = 0 }" $VS_INPUT_FILE) &&
    echo $VS_LINE_NUMBER
    sed -i "$VS_LINE_NUMBER i \\\tOption \"NaturalScrolling\"\t\"true\"" $VS_INPUT_FILE &&
    echo "VERTICAL_SCROLLING=true" >> $RICE_CONFIG_FILE
}
install_dwm() {
    sudo apt install $DWM_PACKAGE_LIST -y
    cd $REPO_DIR
    for i in "${DWM_COMPONENT_LIST[@]}"
    do
        git clone "$GIT_REPO/$i"
    done

    for i in "${DWM_COMPONENT_LIST[@]}"
    do
        cd $i
        git checkout current
        sudo make clean install
        cd -
    done
    cd -
}

install_i3() {
     /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2020.02.03_all.deb keyring.deb SHA256:c5dd35231930e3c8d6a9d9539c846023fe1a08e4b073ef0d2833acd815d80d48
     dpkg -i ./keyring.deb
     echo "deb http://debian.sur5r.net/i3/ $(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" >> /etc/apt/sources.list.d/sur5r-i3.list
     apt update
     sudo apt install $I3_PACKAGE_LIST -y
     install_polybar
     echo "i3" > .xinitrc
     
}


create_directories() {
    mkdir $HOME/dev &&
    mkdir -p $RICE_CONFIG_DIR &&
    mkdir -p $REPO_DIR
}

configure_user() {
    sudo usermod -aG docker $USER
    sudo usermod -aG tty $USER
}


bootstrap() {

    print_install_formatted "Packages"&& install_packages
    create_directories
    configure_user &&
    print_install_formatted "Dotfiles" && install_dotfiles &&
    print_install_formatted "Yarn"&& install_yarn &&
    print_install_formatted "Oh My Tmux" && install_oh_my_tmux &&
    print_install_formatted "Oh My Zsh" && install_oh_my_zsh &&
    print_install_formatted "Additional Fonts" && install_additional_fonts &&
    print_install_formatted "Vertical scrolling" && install_vertical_scrolling

    [ ! -z "$HOTFIX" ] && install_desktop_hotfix
    [ ! -z "$THINKPAD" ] && install_thinkpad_brightness
    
    if [ -z "$DESKTOP" ]; then
        read -p "WARNING: No desktop enviroment selected. Continue? [Y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
        print_install_formatted "Done."
        exit 1
        fi
    fi
    
    print_install_formatted $DESKTOP
    case $DESKTOP in
        dwm)
            install_dwm
            ;;
        i3)
            install_i3
            ;;
    esac

    echo "DESKTOP=$DESKTOP" >> $RICE_CONFIG_FILE

}

cleanup() {
    echo "Cleaning up..."
    rm -rf $HOME/.git
}

purge() {
    read -p "WARNING: This will delete your \$HOME folder. Continue? [Y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
    
    echo "Detecting desktop environment..."
    case $ARG in
        dwm)
            echo "Found $ARG. Purging...."
            purge_dwm
            ;;
        i3)
            echo "Found $ARG. Purging...."
            purge_i3
            ;;
        *)
            echo "No desktop environment found. Won't purge."
            ;;
    esac

    echo "Purging \$HOME..."
    rm -rf $HOME/*
    rm -rf $HOME/.*

    echo "Purging packages..."
    sudo apt remove --purge $PACKAGE_LIST -y

    echo "Setting default shell back to bash..."
    sudo chsh $USER -s /bin/bash
    
    echo "Done"
    
}

purge_dwm() {
    for i in "${DWM_COMPONENT_LIST[@]}"
    do
        sudo rm "/usr/local/bin/$i"
    done
    sudo apt remove --purge $DWM_PACKAGE_LIST -y
}

purge_i3() {
    sudo apt remove --purge $I3_PACKAGE_LIST -y
}

while [ $# -ne 0 ]; do
    ARG=$1
    shift
  case $ARG in
      --hotfix)
          HOTFIX=1
          ;;
      --backup)
          backup
          exit 0
          ;;
      --thinkpad)
          THINKPAD=1
          ;;
      --dwm)
          DESKTOP="dwm"
          ;;
      --i3)
          DESKTOP="i3"
          ;;
      --purge)
          PURGE=1
          ;;
      *) cat <<EOF
My ricing bootstrap script

Options:

        --hotfix        Install audio hotfix for desktop PC
        --backup        Backs up personal repositories
        --dwm           Install DWM desktop, along with dmenu and slstatus
	--i3          	Install i3 WM with polybar
        --thinkpad      Install thinkpad brightness fixes
        --help, -h      Print this documentation
        
EOF
         exit 1
         ;;

  esac
done
echo "I'm gonna need your password"
sudo echo >/dev/null || exit 1

[ -z "$PURGE" ] && bootstrap && exit 0

purge
