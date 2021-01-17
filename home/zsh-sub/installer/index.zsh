#
# This file contains is in charge of installing all components required by the current setup
#

if [[ -z "$ZSH_INSTALLER_DIR" ]]; then
    echoerr "Environment variable \e[93m\$ZSH_INSTALLER_DIR\e[91m is not defined."
    echoerr "       Please make sure the current script is run from Setup Env."
    return 1
fi

export ZSH_INSTALLED_LIST_FILE=$(realpath "$ZSH_INSTALLER_DIR/../local/.installed.auto.zsh")

if [[ ! -f "$ZSH_INSTALLED_LIST_FILE" ]]; then
    echoerr "Installation list was not found at path \e[95m$ZSH_INSTALLED_LIST_FILE\e[91m. Aborting installation."
    return 1
fi

source "$ZSH_INSTALLED_LIST_FILE"

function install_components_from_var() {
    # Choose a temporary directory
    local AUTO_INSTALLER_STARTED_AT=$(date +%s%N)
    INSTALLER_TMPDIR="/tmp/_setupenv_autoinstaller_$AUTO_INSTALLER_STARTED_AT"
    mkdir -p "$INSTALLER_TMPDIR"

    echoinfo "Detected \e[91m${#SETUPENV_TO_INSTALL[@]}\e[93m $1:"
    echo -e "\e[96m    ${SETUPENV_TO_INSTALL[@]}"
    echo -e ""
    echoinfo "These components will now be installed."
    echoinfo "$2type \e[31mN\e[93m/\e[31mn\e[93m."

    local install_choice
    read "install_choice?"

    if [[ $install_choice =~ ^[Nn]$ ]]; then
        echoinfo "Installation has been aborted."
        echo -e ""

        if [[ $3 = 1 ]]; then
            export ZSH_INSTALLER_ABORTED=1
        fi

        return 1
    fi

    echo -e ""
    echosuccess ">"
    echosuccess "> Preparing the environment for update..."
    echosuccess ">"
    echo -e ""

    sudo apt update
    sudo apt install -yqqq wget sed grep unzip jq apt-transport-https dos2unix

    for component in $SETUPENV_TO_INSTALL
    do
        SETUPENV_INSTALL_STEP=$((SETUPENV_INSTALL_STEP + 1))

        echo ""
        echosuccess ">"
        echosuccess "> Installing component \e[94m$SETUPENV_INSTALL_STEP\e[32m /" \
                "\e[91m${#SETUPENV_TO_INSTALL[@]}\e[32m: \e[96m$component\e[32m"
        echosuccess ">"
        echo ""

        local script_path="$ZSH_INSTALLER_DIR/scripts/all/$component.zsh"

        if [[ ! -f $script_path ]]; then
            local script_path="$ZSH_INSTALLER_DIR/scripts/$ENV_NAME_STR/$component.zsh"

            if [[ ! -f $script_path ]]; then
                echoerr "> Failed to install component \e[96m$component\e[91m: installation script not found"
                return 1
            fi
        fi

        export ZER_UPDATING=$5

        if source "$script_path"; then
            local var_name="SETUPENV_INSTALLED_${${component//-/_}:u}"

            if [[ -z "${(P)var_name}" ]]; then
                echo "export $var_name=1" >> "$ZSH_INSTALLED_LIST_FILE"
            fi
        fi
    done

    unset ZER_UPDATING

    echo -e ""
    echosuccess ">"
    echosuccess "> Cleaning the temporary directory..."
    echosuccess ">"
    echo -e ""

    command rm -rf "$INSTALLER_TMPDIR"

    echo -e ""
    echoinfo "=> Successfully $4 \e[91m${#SETUPENV_TO_INSTALL[@]}\e[93m component(s)!"
    echo -e ""
}

function check_component() {
    local script_name="${1/.zsh/}"
    local var_name="SETUPENV_INSTALLED_${${script_name//-/_}:u}"

    if [[ -z "${(P)var_name}" ]]; then
        SETUPENV_TO_INSTALL+=("$script_name")
    fi
}

function zerupdate_component() {
    if [[ ! -f "$ZSH_INSTALLER_DIR/scripts/all/$1.zsh" && ! -f "$ZSH_INSTALLER_DIR/scripts/$ENV_NAME_STR/$1.zsh" ]]; then
        echoerr "Provided component \e[96m$1\e[91m was not found."
        return 1
    fi

    SETUPENV_TO_INSTALL=()

    for component in "$@"
    do
        SETUPENV_TO_INSTALL+=("$component")
    done

    SETUPENV_INSTALL_STEP=0

    install_components_from_var "components to update" "To abort the update process, " 0 "updated" 1

    unset SETUPENV_TO_INSTALL
    unset SETUPENV_INSTALL_STEP
}

function _step() {
    echo -e ""
    echoinfo ">>> Sub-step: $1"
    echo -e ""
}

SETUPENV_TO_INSTALL=()

for file in "$ZSH_INSTALLER_DIR/scripts/"{all,$ENV_NAME_STR}/*.zsh
do
    check_component "$(basename "$file")"
done

SETUPENV_INSTALL_STEP=0

if [[ ${#SETUPENV_TO_INSTALL[@]} != 0 ]]; then
    install_components_from_var "missing components" "To skip the installation process for now and not load the environment, " 1 "installed" 0
fi

unset SETUPENV_TO_INSTALL
unset SETUPENV_INSTALL_STEP
unset INSTALLER_TMPDIR
