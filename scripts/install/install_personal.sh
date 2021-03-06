#!/bin/bash


LOG_FILE_DIR="${HOME}/log"
LOG_FILE="$(date +"%Y-%m-%dT%H:%M:%S")_$(basename -- $0).log"

SCRIPTPATH="$(realpath -s $0)"
SCRIPTDIR=$(dirname ${SCRIPTPATH})
DOTFILES_ROOT="$(realpath "${SCRIPTDIR}/../..")"

############################################## EXTERNAL DEPENDENCIES SCRIPTS ###

# Ansi color code variables
if [[ -e "${SCRIPTDIR}/../colors" ]]; then
  source "${SCRIPTDIR}/../colors"
else
  echo "${SCRIPTPATH} WARNING: Failed to source '../colors' dependency"
  echo
fi
# Utility functions
if [[ -e "${SCRIPTDIR}/../utils" ]]; then
  source "${SCRIPTDIR}/../utils"
else
  echo "${SCRIPTPATH} ERROR: Failed to source '../utils' dependency"
  exit 1
fi
# Install utility functions
if [[ -e "${SCRIPTDIR}/install_utils.sh" ]]; then
  source "${SCRIPTDIR}/install_utils.sh"
else
  echo "${SCRIPTPATH} ERROR: Failed to source './install_utils.sh' dependency"
  exit 1
fi

############################################################### FLAG OPTIONS ###

# Display help
usage() {
  cat << EOF
USAGE:

Command description.

  command [ -DsvVy ]

OPTIONS:

  -D  debug mode (redirect output in log file)
  -s  silent output
  -v  verbose output
  -V  very verbose output
  -y  skip confirmation
  -h  help

EOF
}

# Set flag options
while getopts "DsvVyh" opt; do
  case "$opt" in
    D) [[ -n "$DEBUG"           ]] && unset DEBUG                      || DEBUG=true;;
    s) [[ -n "$IS_SILENT"       ]] && unset IS_SILENT                  || IS_SILENT=true;;
    v) [[ -n "$IS_VERBOSE"      ]] && unset IS_VERBOSE                 || IS_VERBOSE=true;;
    V) [[ -n "$IS_VERY_VERBOSE" ]] && unset IS_VERBOSE IS_VERY_VERBOSE || IS_VERBOSE=true; IS_VERY_VERBOSE=true;;
    y) [[ -n "$SKIP_CONFIRM"    ]] && unset SKIP_CONFIRM               || SKIP_CONFIRM=true;;
    h) usage && exit 0;;
    *) usage && echo -e "${SCRIPTPATH}:\n${RED}ERROR: Invalid flag.${NC}"
      exit 1
  esac
done 2>/dev/null
shift "$((OPTIND-1))"

####################################################### PRE-EXECUTION SET UP ###

# Strip trailing '/' in DIR path variables
LOG_FILE_DIR=$(echo ${LOG_FILE_DIR} | sed 's,/*$,,')

# Log stdout and stderr to $LOG_FILE in $LOG_FILE_DIR
if [[ -n "${DEBUG}" ]]; then
  # Append LOG_FILE
  LOG_FILE_PATH="${LOG_FILE_DIR}/${LOG_FILE}"
  # Create log directory if not existing
  if [[ ! -d "${LOG_FILE_DIR}" ]]; then
    mkdir -p "${LOG_FILE_DIR}"
  fi
  # Initialize log file
  echo -e "${SCRIPTPATH} log outputs\n" > ${LOG_FILE_PATH}
fi

################################################## SCRIPT ARGUMENTS HANDLING ###

##################################################### SCRIPT MAIN EXECUTIONS ###

# Confirmation
if [[ -z "${SKIP_CONFIRM}" ]]; then
  log "Do you wish to continue? (Y/y): \n" 1
  ${SCRIPTDIR}/../confirm "Do you wish to continue? (Y/y): "
  if [[ "${?}" -eq 1 ]]; then
    abort "${SCRIPTPATH}: Aborted."
  elif [[ "${?}" -eq 2 ]]; then
    error "${SCRIPTPATH}: Unsupported shell"
  fi
fi

DOWNLOADS_DIR="${HOME}/Downloads"
TRASH_DIR="${HOME}/.Trash"
PACKAGES="${SCRIPTDIR}/packages"

cd ${DOWNLOADS_DIR}

successful_packages=""
failed_packages=""
skipped_packages=""

# Internet connection issue on apt update workaround for WSL2
if [[ "$(grep -i microsoft /proc/version)" ]]; then
  cat /etc/resolv.conf > ~/nameserver.txt
  echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
fi

# Apt update and upgrade
if ! sudo apt update && sudo apt upgrade -y; then
  error "Apt update and upgrade failed" 1
fi

# restore nameserver
if [[ "$(grep -i microsoft /proc/version)" ]]; then
  cat ~/nameserver.txt | sudo tee /etc/resolv.conf
fi


#################### Dotfiles ####################

if git clone https://github.com/marklcrns/scripts $HOME/scripts; then
  cd ~/.dotfiles
  # Distribute all dotfiles from `~/.dotfiles` into `$HOME` directory
  $HOME/scripts/tools/dotfiles/dotdist -VD -r .dotfilesrc . $HOME

  # Source .profile
  source ${HOME}/.profile
fi

############### Text Editors ##################

# Personal neovim config files
if git_clone "https://github.com/marklcrns/nvim-config" "${HOME}/.config/nvim/"; then
  make
fi

# Clone Vimwiki wikis
[[ -d "${HOME}/Documents/wiki" ]] && rm -rf ~/Documents/wiki
[[ ! -d "${HOME}/Documents" ]] && mkdir -p "${HOME}/Documents"
git_clone "https://github.com/marklcrns/wiki" "${HOME}/Documents/wiki" && \
  git_clone "https://github.com/marklcrns/wiki-wiki" "${HOME}/Documents/wiki/wiki"

#################### Session Manager ####################

# Tmuxinator
git_clone "https://github.com/marklcrns/.tmuxinator" "${HOME}/.tmuxinator"

#################### Misc ####################

# Personal Timewarrior configuration files
git_clone "https://github.com/marklcrns/.timewarrior" "${HOME}/.timewarrior"
# Taskwarrior hooks
if git_clone "https://github.com/marklcrns/.task" "${HOME}/.task"; then
  cd ${HOME}/.task && ./scripts/install.sh
fi

# Credentials for taskwarrior, calendar.vim, and rclone cloud accounts
if git clone https://github.com/marklcrns/.secret $home/.secret; then
  cd ~/.secret
  ./setup.sh
fi


#################################################################### WRAP UP ###

total_count=0
successful_count=0
skipped_count=0
failed_count=0

echolog
echolog "${UL_NC}Successful Installations${NC}"
echolog
while IFS= read -r package; do
  if [[ -n ${package} ]]; then
    ok "${package}"
    total_count=$(expr ${total_count} + 1)
    successful_count=$(expr ${successful_count} + 1)
  fi
done < <(echo -e "${successful_packages}") # Process substitution for outside variables

echolog
echolog "${UL_NC}Skipped Installations${NC}"
echolog
while IFS= read -r package; do
  if [[ -n ${package} ]]; then
    warning "${package}"
    total_count=$(expr ${total_count} + 1)
    skipped_count=$(expr ${skipped_count} + 1)
  fi
done < <(echo -e "${skipped_packages}") # Process substitution for outside variables

echolog
echolog "${UL_NC}Failed Installations${NC}"
echolog
while IFS= read -r package; do
  if [[ -n ${package} ]]; then
    error "${package}"
    total_count=$(expr ${total_count} + 1)
    failed_count=$(expr ${failed_count} + 1)
  fi
done < <(echo -e "${failed_packages}") # Process substitution for outside variables

echolog
echolog "Successful installations:\t${successful_count}"
echolog "Skipped installations:\t${skipped_count}"
echolog "failed installations:\t${failed_count}"
echolog "${BO_NC}Total installations:\t\t${total_count}"

finish 'PERSONAL INSTALLATION COMPLETE!'

