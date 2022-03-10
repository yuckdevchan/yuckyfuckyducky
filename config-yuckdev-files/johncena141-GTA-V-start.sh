#!/bin/bash
# Brought to you by the johncena141 release group on 1337x.to
cd "$(dirname "$0")" || exit
echo -e "\e[38;5;$((RANDOM%257))m
   ▄▄        ▄▄
   ██       ███
             ██                                               ▄▄▄          ▄▄▄
 ▀███ ▄████▄ ██████▄▀███████▄  ▄████  ▄▄█▀██▀███████▄  ▄█▀██▄▀███      ▄██▀███
   ████▀  ▀████   ██  ██   ██ ██▀ ██ ▄█▀   ██ ██   ██ ██   ██  ██     ████  ██
   ████    ████   ██  ██   ██ ██     ██▀▀▀▀▀▀ ██   ██  ▄█████  ██   ▄█▀ ██  ██
   ████▄  ▄████   ██  ██   ██ ██▄   ▄██▄    ▄ ██   ██ ██   ██  ██ ▄█▀   ██  ██
   ██ ▀████▀████ ████████ ████▄█████▀ ▀█████▀████ ████▄████▀██████▄████████████▄
██ ██                                                                  ██
▀███                                                                   ██
             Pain heals. Chicks dig scars. Glory lasts forever! \e[0m"
# Wine settings
export WINEESYNC=1
export WINEFSYNC=1
export WINEDLLOVERRIDES="mscoree=d;mshtml=d;dinput8=n,b"
export STAGING_SHARED_MEMORY=1; export WINE_LARGE_ADDRESS_AWARE=1
export WINE="$PWD/game/files/wine/bin/wine"
#export WINE="$(which wine)"

# Wineprefix
export WINEARCH=win64
export WINEPREFIX="$PWD/game/prefix"

# Game files
export EXE="GTAVLauncher.exe"
export GAME_FOLDER="game/files"

# Extra
PREFIX="$PWD/game/prefix"; WINETRICKS="$PWD/winetricks"; SYSWINETRICKS="$(which winetricks 2>/dev/null)"; GAMEMODE="$(which gamemoderun 2>/dev/null)"; export WINEDEBUG="-all"; res_x="$(xrandr | awk -F '[ , ]' '/current/ {print $9}')"; res_y="$(xrandr | awk -F '[ , ]' '/current/ {print $11}')"; RESOLUTION="$(xrandr | awk -F '[ , ]' '/current/ {print $9$10$11}')"

# Forbid root rights
[ "$EUID" = "0" ] && echo -e "\e[91mDon't use sudo or root user to execute these scripts!\e[0m" && exit

# Check drive format
[ "$(df -T . | xargs | awk '{print $10}')" = "ntfs" ] && echo "ntfs drive format detected, we recommend that you use ext4 or btrfs" || echo "$(df -T . | xargs | awk '{print $10}') drive format detected"

# Check for winetricks
[ -n "$SYSWINETRICKS" ] && WINETRICKS=$SYSWINETRICKS && echo "using system winetricks" || echo "using github winetricks"
[ ! -x "$WINETRICKS" ] && echo "github winetricks not found, fetching..." && curl -L "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" -o winetricks && chmod +x winetricks
[ ! -x "$WINETRICKS" ] && echo -e "\e[91mCould not fetch winetricks and not installed in system\e[0m" && exit 1

[ ! -e "$PREFIX/drive_c" ] && echo "vcrun2012 is not installed, installing now" && $WINE game/vcredist_x64.exe /q || echo "vcrun2012 is installed"

# Install and auto-update dxvk
export DXVK_FRAME_RATE=0 && export DXVK_LOG_PATH=none
DXVKVER="$(curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | awk -F '["/]' '/"browser_download_url":/ {print $11}' | cut -c 2-)"
SYSDXVK=$(which setup_dxvk 2>/dev/null); SYSDXVKVER=$(pacman -Qi dxvk-bin 2>/dev/null | awk -F": " '/Version/ {print $2}' | awk -F"-" '{ print $1 }')
install_dxvk() {
    [ -n "$SYSDXVK" ] && echo "installing dxvk from system" && $WINE wineboot -i && wineserver -w && $SYSDXVK install && echo "$SYSDXVKVER" > "$PWD/game/prefix/.sysdxvk" && wineserver -k
    [ -z "$SYSDXVK" ] && echo "installing dxvk from winetricks" && $WINETRICKS -q dxvk && echo "$DXVKVER" > "$PWD/game/prefix/.dxvk"
}

[[ ! -f "$PWD/game/prefix/.sysdxvk" && -z "$(awk '/dxvk/ {print $1}' "$PREFIX/winetricks.log" 2>/dev/null)" ]] && install_dxvk || echo "dxvk is installed"
[[ -f "$PWD/game/prefix/.sysdxvk" && "$(cat "$PWD/game/prefix/.sysdxvk")" != "$SYSDXVKVER" ]] && echo "updating dxvk from system" && install_dxvk
[[ -f "$PWD/game/prefix/.dxvk" && -n "$DXVKVER" && "$DXVKVER" != "$(awk '{print $1}' "$PWD/game/prefix/.dxvk")" ]] && echo "newer dxvk version found, installing" && install_dxvk

# Start the game
cd "$GAME_FOLDER" || exit
"$WINE" "$EXE"
