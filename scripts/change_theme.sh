# /bin/bash

#
# This script is used to manipulate themes of Hyprthemes.
#
# Usage:
# -t    Change theme
# -m    Change theme mode (light/dark) if it exists
# -d    Enable debug messages (useful for in shell execution)
#
# It MUST be used only after setup.sh has been executed inside a shell. 
# It detects if setup.sh has never been launched.
#
#
# Before doing anything, it detects if all the dependencies are installed.
# (Must be moved to setup.sh)
# 
# It checks if the current theme is in light or dark mode to preserve the mode
# after a call to change.
#


# function _colors()
# function change_theme_mode()
# function change_theme()

function main()
{

        source "/home/eluciani/.bashrc"

        # Important variables !
        # $HYPRTHEMES_DIR => is defined in your .bashrc/.zshrc after 
        # setup.sh execution

        #= Add themes names here. It must be the same name as 
        #= the theme directory
        declare -g -A themes_list=(
        )

        local a=1
        for i in "${HYPRTHEMES_DIR}/themes/"*; do
                local theme_name=$(basename "${i}")
                themes_list["${a}"]="${theme_name}"
                (( a++ ))
        done




        
        # Beginning of the action #

        # Options
        local opt_t=0 # Change theme
        local opt_m=0 # Change theme mode (light/dark)
        local opt_d=0 # Enable debug mode
        local _opt=0  # Check if an option is used (because it should be used)

        OPTIND=1

        while getopts "tmd" opt; do
                _opt=1 # An option has been used
                case "${opt}" in
                        t) opt_t=1 ;;
                        m) opt_m=1 ;;
                        d) opt_d=1 ;;
                        *) usage exit 1 ;;
                esac
        done

        shift $((OPTIND-1))

        # If no option is used
        if [[ "${_opt}" -eq 0 ]]; then
                printf "This script cannot be used without option.\n"
                usage
                exit 1
        fi

        # If -d is used
        if [[ "${opt_d}" -eq 1 ]]; then
                # Init colors
                _colors
        fi

        # If -m and -t are used simulteanously
        if [[ "${opt_t}" -eq 1 && "${opt_m}" -eq 1 ]]; then
                if [[ "${opt_d}" -eq 1 ]]; then
                        printf "${DB} Only -t or -m can be used. Not both.\n"
                fi
                exit 1
        fi

        # If -t is used
        if [[ "${opt_t}" -eq 1 ]]; then
                # THEME MANAGEMENT
                update_theme "theme" 
        fi

        # If -m is used
        if [[ "${opt_m}" -eq 1 ]]; then
                # THEME MODE MANAGEMENT
                update_theme "mode" 
        fi

        exit 0
}

function usage()
{
        printf "Usage:\n"
        printf "  -d       Debug messages\n"
        printf "  -m       Change theme mode (light/dark)\n"
        printf "  -t       Change theme\n\n"
}

function _colors()
{
        R="\033[91m"
        G="\033[92m"
        Y="\033[93m"
        B="\033[94m"
        P="\033[95m"
        C="\033[96m"
        N="\033[0m"

        INFO="${C}[>]${N}"
        ERR="${R}[!]${N}"
        WARN="${Y}[@]${N}"
        SUC="${G}[*]${N}"
        QS="${B}::${N}"
        DB="${R}[DEBUG]${N}"
}

function update_theme()
{

        # ${1} should be either "theme" or "mode"

        # DEBUG
        if [[ "${1}" == "mode" ]]; then
                printf "${DB} Changing theme mode...\n"
        elif [[ "${1}" == "theme" ]]; then
                printf "${DB} Changing theme...\n"
        fi

        # List available themes
        for i in "${!themes_list[@]}"; do
                printf "${i} - ${themes_list[${i}]}\n"
        done

        # Read actual theme
        local current_theme=$(
                tail -2 "${HOME}/.config/hypr/hyprland_theme.conf" | head -1
        )
        
        # Read theme mode (light or dark)
        local theme_mode=$(tail -1 "${HOME}/.config/hypr/hyprland_theme.conf")
        local next_mode=""

        if [[ "${1}" == "theme" ]]; then
                local current_key=""
                local next_key=""
                local next_theme=""

                # Get the key for actual theme
                for key in "${!themes_list[@]}"; do
                        if [[ "${themes_list[${key}]}" == "${current_theme}" ]]; then
                                current_key="${key}"
                                break
                        fi
                done

                # Total number of themes
                local max_key=$((${#themes_list[@]}))

                # Reset to first key if it's the end, else, increment
                if [[ "${current_key}" -eq "${max_key}" ]]; then
                        next_key=1
                else
                        next_key=$((current_key + 1))
                fi

                next_theme="${themes_list[${next_key}]}"
                next_mode="${theme_mode}"
                local path="${HYPRTHEMES_DIR}/themes/${next_theme}/${theme_mode}"
        elif [[ "${1}" == "mode" ]]; then
                # Intervert themes
                [[ "${theme_mode}" == "light" ]] && next_mode="dark"
                [[ "${theme_mode}" == "dark" ]] && next_mode="light"
                local path="${HYPRTHEMES_DIR}/themes/${current_theme}/${next_mode}"
                next_theme="${current_theme}"
        fi

        # DEBUG
        if [[ "${opt_d}" -eq 1 ]]; then
                printf "${DB} Actual theme: ${current_theme}\n"
                printf "${DB} Actual mode: ${theme_mode}\n"
                if [[ "${1}" == "theme" ]]; then
                        printf "${DB} Next theme: ${next_theme}\n"
                elif [[ "${1}" == "mode" ]]; then
                        printf "${DB} Next mode: ${next_mode}\n"
                fi
                printf "${DB} Theme path: ${path}\n"
        fi

        # Check if the theme mode can be changed, if not, revert to 
        # the previous one
        if [[ ! -d "${path}" ]]; then
                next_mode="${theme_mode}"
        fi

        # 1. swww - Wallpaper
        if ! swww img \
        --transition-duration 1 \
        --transition-fps 60 \
        --transition-type right \
        --transition-step 25 \
        "${path}/Wallpapers/background.png" \
        1> "/dev/null" 2>&1; then
                # DEBUG
                if [[ "${opt_d}" -eq 1 ]]; then
                        printf "${DB} swww could not change the wallpaper.\n"
                fi
        fi

        # 2. Hyprland - Wayland Compositor
        command cp -f "${path}/hypr/hyprland.conf" \
        "${HOME}/.config/hypr/hyprland.conf" 1> "/dev/null" 2>&1

        command cp -f "${HYPRTHEMES_DIR}/GENERIC/hypr/"* \
        "${HOME}/.config/hypr/" 1> "/dev/null" 2>&1

        { # Update the file hyprland_theme.conf for future theme changes
                echo -e "DO NOT EDIT THIS FILE! IT IS USED BY HYPRTHEMES"
                echo -e "${next_theme}"
                echo -e "${next_mode}"
        } > "${HOME}/.config/hypr/hyprland_theme.conf"

        # 3. Hyprlock - Lockscreen
        echo -e "source = ${path}/hypr/hyprlock/hyprlock.conf" \
        > "${HOME}/.config/hypr/hyprlock.conf"

        # 4. Rofi - Applications launcher
        command cp -f "${path}/rofi/"* "${HOME}/.config/rofi/" \
        1> "/dev/null" 2>&1

        # 5. Waybar - Taskbar
        command rm -rf "${HOME}/.config/waybar"
        command cp -rf "${path}/waybar" "${HOME}/.config/" \
        1> "/dev/null" 2>&1
        killall waybar 1> "/dev/null" 2>&1
        hyprctl dispatch -- exec waybar 1> "/dev/null" 2>&1

        command cp -f "${HYPRTHEMES_DIR}/scripts/change_theme.sh" \
        "${HOME}/.config/waybar" 1> "/dev/null" 2>&1

        # 6. Alacritty - Terminal emulator
        echo "general.import = [ \"${path}/alacritty/alacritty.toml\" ]" \
        > "${HOME}/.config/alacritty/alacritty.toml"
}

main "${@}"
