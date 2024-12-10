#! /bin/bash

#
# This script MUST BE LAUNCHED as the first one before anything else after the 
# repository has been downloaded. Otherwise, any theme will work.
#
# It automatically detects the path where the repository is located on
# the system. Then, it adds an environment variable with the path.
# It is used by change_theme.sh and configurations files.
#
# It aims to be modular and to avoid static path. The user must control where 
# they want the repository on their system.
#
# If the automatic path does not satisfy the user, the user can write it 
# manually, but the script will only check if the path exists on the system, not
# if it's correct.
#
# Something else: The script make a backup of all your dotfiles. Like that, the
# change_theme.sh and change_theme_mode.sh scripts cannot destroy your personnal
# files. The backup is saved at "${HOME}/.config/YOUR_DOTFILES_BACKUP".
#
# /!\ It only does a backup of the files modified by the themes. /!\
#
# 2ELCN0168©
#
# Thank you for using my work.
#

source "./include/colors.sh"

function check_dependencies()
{
        local dependencies=(
                "swww"
                "rofi"
                "alacritty"
                "waybar"
        )
        
        local missing_dependencies=()
        
        for i in "${dependencies[@]}"; do
                if ! hash "${i}" 1> "/dev/null" 2>&1; then
                        missing_dependencies+=("${i}")
                fi
        done

        if [[ ! -z "${missing_dependencies[@]}" ]]; then
                printf "${ERR} There are missing dependencie(s):\n"
                for i in "${missing_dependencies[@]}"; do
                        printf "%s ${Y}${i}${N}\n" "-"
                done
                printf "\n"
        fi
}

function set_themes_dir()
{
        printf "\n"
        printf "${C}${INFO}${Y} Hello there!${N}\n"
        printf "Welcome to my personnal themes for ${Y}Hyprland${N} on "
        printf "${C}Archlinux ${B}%s${N}!\n\n" "/\\"
        printf "It seems that the themes directory is located at "
        printf "${P}${1}${N}.\n"
        printf "${QS} Is that correct? ${G}[Y/n]${N} -> "

        local ans_dir=""

        while true; do
                if ! read -r ans_dir; then
                        handle_interrupt
                        exit 1
                fi
                : "${ans_dir:=Y}"
                printf "\n"

                [[ "${ans_dir}" =~ ^[yYnN]$ ]] && break

                printf "${Y}${WARN}${N} Invalid answer.\n"
                printf "${C}Type again${N} -> "
        done

        case "${ans_dir}" in
                [yY]) return 0 ;;
                [nN]) return 1 ;;
        esac
}

function ask_path()
{
        printf "${QS} Write the path of the directory, if you're not "
        printf "sure about what to type, you can get the current path with "
        printf "${P}\"realpath ../\"${N}. -> "

        local ans_path

        while true; do
                read -r ans_path
                printf "\n"
                
                if [[ -d "${ans_path}" ]]; then
                        printf "Directory is ${P}\"${ans_path}\"${N}\n"
                        user_defined_path="${ans_path}"
                        break
                else

                        printf "${ERR} It seems that the directory is not "
                        printf "valid, type again -> "
                fi
        done
}

function export_themes_var()
{
        local shellrc=()

        local tempfile=$(mktemp)

        # Check if user has each .bashrc and .zshrc
        for i in .bashrc .zshrc; do
                [[ -f "${HOME}/${i}" ]] && shellrc+=("${HOME}/${i}")
        done

        # Check if a shellrc exists in user's directory
        if [[ -z "${shellrc}" ]]; then
                printf "${ERR} You have no .bashrc or .zshrc, create one "
                printf "before. Exit 1\n"
                exit 1
        fi

        for i in "${shellrc[@]}" "${tempfile}"; do
                # Delete old HYPRTHEMES lines
                sed -i '/^### =ID321==== ###/,/^### =ID321==== ###/d' "${i}" \
                2> "/dev/null"

                {
                echo -e "### =ID321==== ###"
                echo -e "# HYPRTHEMES"
                echo -e "# DO NOT EDIT THIS ENTIRE BLOC! TO UPDATE IT, RE-RUN"
                echo -e "# \"setup.sh\" AND IT WILL BE DONE AUTOMATICALLY!"
                echo -e "export HYPRTHEMES_DIR=\"${1}\""
                echo -e "PATH=\${HYPRTHEMES_DIR}/scripts:\${PATH}"
                echo -e "### =ID321==== ###"
                } >> "${i}"
        done

        printf "${SUC} The following lines has been added to your "
        echo -e "${P}${shellrc[@]}${N}\c"
        printf ":\n\n"

        printf "${Y}"
        cat "${tempfile}" 
        printf "${N}"

        printf "\n"

        command rm -rf "${tempfile}"
}

function backup_dotfiles()
{
        if [[ -d "${HOME}/.config/YOUR_DOTFILES_BACKUP" ]]; then

                local ans_delete=""

                printf "${R}:: DESTRUCTIVE OPERATION INCOMING! ::${N}\n"
                printf "${WARN} ${Y}There is already a backup for your "
                printf "dotfiles at "
                printf "${P}${HOME}/.config/YOUR_DOTFILES_BACKUP${N}.\n"
                printf "${B}:: ${N}Do you want to quit or "
                printf "recreate it? ${C}[Q/y]${N} -> "

                while true; do
                        if ! read -r ans_delete; then
                                handle_interrupt
                                exit 1
                        fi
                        : "${ans_dir:=Q}"
                        printf "\n"

                        case "${ans_delete}" in
                                [yY]) break ;;
                                [qQ]) exit 0 ;;
                                *) 
                                printf "${Y}${WARN}${N} "
                                printf "Invalid answer.\n${C}Type again${N} -> "
                                ;;
                        esac
                done
        fi

        command rm -rf "${HOME}/.config/YOUR_DOTFILES_BACKUP" \
        1> "/dev/null" 2>&1

        mkdir "${HOME}/.config/YOUR_DOTFILES_BACKUP"
        
        for i in "${1}"; do
                cp -rf "${HOME}/.config/${i}" \
                "${HOME}/.config/YOUR_DOTFILES_BACKUP"
        done

        printf "${INFO} A directory has been created at "
        printf "\"~/.config/YOUR_DOTFILES_BACKUP\" in order to preserve your "
        printf "files to be lost by this script.\n\n"

}

function handle_interrupt()
{
        printf "\n\n"
        printf "${R}:: ${C}The script has been exited by the user. "
        printf "${Y}Exit code 0. ${R}::${N}"
        printf "\n\n"
        exit 0
}

function create_hyprthemes_scripts_dir()
{
        if [[ ! -d "${HOME}/.config/Hyprthemes_modules/" ]]; then
                mkdir "${HOME}/.config/Hyprthemes_modules/"
        fi

        cp -rf "./change_theme.sh" "${HOME}/.config/Hyprthemes_modules"
}

function main()
{
        _colors

        check_dependencies

        themes_dir=$(realpath "../")

        trap 'handle_interrupt' SIGINT

        if set_themes_dir "${themes_dir}" -eq 0; then
                export_themes_var "${themes_dir}"
        else
                ask_path
                export_themes_var "${user_defined_path}"
        fi

        impacted_directories=(
                "hypr"
                "waybar"
                "rofi"
                "alacritty"
                "swaync"
        )

        backup_dotfiles "${impacted_directories[@]}" 

        create_hyprthemes_scripts_dir
}

main
