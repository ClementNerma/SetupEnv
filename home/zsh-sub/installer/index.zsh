#
# This file contains is in charge of installing all components required by the current setup
#

if [[ -z "$ZSH_INSTALLER_DIR" ]]; then
    echo -e "\e[91mERROR: Environment variable \e[93m\$ZSH_INSTALLER_DIR\e[91m is not defined.\e[0m"
    echo -e "\e[91m       Please make sure the current script is run from Setup Env.\e[0m"
    return
fi

export ZSH_INSTALLED_LIST_FILE=$(realpath "$ZSH_INSTALLER_DIR/../local/.installed.auto.zsh")

if [[ ! -f "$ZSH_INSTALLED_LIST_FILE" ]]; then
    echo -e "\e[91mERROR: Installation list was not found at path \e[95m$ZSH_INSTALLED_LIST_FILE\e[91m. Aborting installation.\e[0m"
    return
fi

source "$ZSH_INSTALLED_LIST_FILE"

function check_component() {
    local script_name="${file/.zsh/}"
    local var_name="SETUPENV_INSTALLED_${${script_name//-/_}:u}"

    if [[ -z "${(P)var_name}" ]]; then
        SETUPENV_TO_INSTALL+=("$script_name")
    fi
}

function install_component() {
    source "$ZSH_INSTALLER_DIR/scripts/$1.zsh"
    echo "export SETUPENV_INSTALLED_${${1//-/_}:u}=1" >> "$ZSH_INSTALLED_LIST_FILE"
}

function _step() {
    echo -e ""
    echo -e "\e[93m>>> Sub-step: $1\e[0m"
    echo -e ""
}

SETUPENV_TO_INSTALL=()

for file in $(\ls "$ZSH_INSTALLER_DIR/scripts/" -1A)
do
    check_component "$file"
done

SETUPENV_INSTALL_STEP=0

if [[ ${#SETUPENV_TO_INSTALL[@]} != 0 ]]; then
    # Choose a temporary directory
    local AUTO_INSTALLER_STARTED_AT=$(date +%s%N)
    INSTALLER_TMPDIR="/tmp/_setupenv_autoinstaller_$AUTO_INSTALLER_STARTED_AT"
    mkdir -p "$INSTALLER_TMPDIR"

    echo -e "\e[93mDetected \e[91m${#SETUPENV_TO_INSTALL[@]} missing components:\e[0m"
    echo -e "\e[96m    ${SETUPENV_TO_INSTALL[@]}\e[0m"
    echo -e ""
    echo -e "\e[93mThese components will now be installed.\e[0m"
    echo -e "\e[93mTo skip the installation process for now and not load the environment, type \e[31mN\e[93m/\e[31mn\e[93m.\e[0m"

    local install_choice
    read "install_choice?"

    if [[ $install_choice =~ ^[Nn]$ ]]; then
        echo -e "\e[93mInstallation has been aborted.\e[0m"
        echo -e ""
        export ZSH_INSTALLER_ABORTED=1
        return
    fi

    echo -e ""
    echo -e "\e[32m>\e[0m"
    echo -e "\e[32m> Preparing the environment for update...\e[0m"
    echo -e "\e[32m>\e[0m"
    echo -e ""

    sudo apt update
    sudo apt install wget curl sed grep unzip zipinfo apt-transport-https dos2unix

    for component in $SETUPENV_TO_INSTALL
    do
        SETUPENV_INSTALL_STEP=$((SETUPENV_INSTALL_STEP + 1))

        echo ""
        echo -e "\e[32m>\e[0m"
        echo -e "\e[32m> Installing component \e[94m$SETUPENV_INSTALL_STEP\e[32m /" \
                "\e[91m${#SETUPENV_TO_INSTALL[@]}\e[32m: \e[96m$component\e[32m\e[0m"
        echo -e "\e[32m>\e[0m"
        echo ""

        install_component "$component"
    done

    echo -e ""
    echo -e "\e[32m>\e[0m"
    echo -e "\e[32m> Cleaning the temporary directory..."
    echo -e "\e[32m>\e[0m"
    echo -e ""

    rm -rf "$INSTALLER_TMPDIR"

    echo -e ""
    echo -e "\e[93m=> Successfully installed \e[91m${#SETUPENV_TO_INSTALL[@]}\e[93m component(s)!\e[0m"
    echo -e ""
fi

unset SETUPENV_TO_INSTALL
unset SETUPENV_INSTALL_STEP
unset INSTALLER_TMPDIR

unset -f _step
unset -f check_component
unset -f install_component
