#!/bin/bash

# Migrate Mercurial to Git
# - github.com/HMKnapp

function _usage {
  _echo_err "Migrate Mercurial to Git"
  _echo_err "https://github.com/HMKnapp/migrate-mercurial-to-git\n"
  _echo_err "Usage:"
  _echo_err "./${SCRIPT_NAME} <hg-repo-url> <git-repo-url>"
  _echo_err "\nor\n"
  _echo_err "export GIT_PREFIX=\"https://gitlab.com/user/group/\""
  _echo_err "./${SCRIPT_NAME} <hg-repo-url>"
  _echo_err "\n"
  exit 1
}

function _echo_err {
	echo -e ${@} >&2
}

function _abort {
	_echo_err "${@}"
	exit 1
}

function _check_auth_vars {
  for VAR in HG_USER HG_PASS; do
    if [[ -z "${!VAR}" ]]; then
          echo "$VAR not set"
          VARMISSING=true
    fi
  done
  [[ ${VARMISSING} == "true" ]] && _abort "Set usernames and passwords in ENV!"
}

function _get_fast_export_script {
  FE_DIR=${TMPDIR}fast-export
  FE_SH=${FE_DIR}/hg-fast-export.sh
  if [[ ! -f ${FE_SH} ]]; then
    _echo_err "fast-export not found. Cloning to ${FE_DIR}"
    git clone https://github.com/frej/fast-export.git "${FE_DIR}"
  fi
}

function _create_temp_folders {
  _TMP_DIR=$(mktemp -d)
  HG_FOLDER="${_TMP_DIR}/hg/${REPO_NAME}"
  GIT_FOLDER="${_TMP_DIR}/git/${REPO_NAME}"
  mkdir -p "${HG_FOLDER}" "${GIT_FOLDER}"
  _echo_err "\nCreating temporary folders:\nHG_FOLDER: ${HG_FOLDER}\nGIT_FOLDER: ${GIT_FOLDER}"
}

function _clone_hg_repo {
  _echo_err "Cloning ${HG_REPO_URL} to ${HG_FOLDER}..."
  HG_AUTH_PREFIX=$(cut -d/ -f1-3 <<< ${HG_REPO_URL})
  cd "${HG_FOLDER}" || _abort "switch to HG_FOLDER failed"
  #hg clone -u --config auth.x.prefix="${HG_AUTH_PREFIX}/" --config auth.x.username="${HG_USER}" --config auth.x.password="${HG_PASS}" "${HG_REPO_URL}" || _abort "Cloning hg repo failed"
  hg --config ui.interactive=yes clone "${HG_REPO_URL}" . || _abort "Cloning hg repo failed"
}

function _clone_git_repo {
  _echo_err "Cloning ${GIT_REPO_URL} to ${GIT_FOLDER}..."
  cd "${GIT_FOLDER}" || _abort "switch to GIT_FOLDER failed"
  git -c http.sslVerify=false clone "${GIT_REPO_URL}" . || _abort "Cloning empty git repo failed. Make sure it exists!"
  git config core.ignoreCase false
}

function _create_git_repo {
  _echo_err "Creating Git repo in ${GIT_FOLDER}..."
  cd "${GIT_FOLDER}" || _abort "switch to GIT_FOLDER failed"
  git init
  git config core.ignoreCase false
  git remote add origin "${GIT_REPO_URL}"
}

function _fast_export {
  _echo_err "Launching fast-export inside GIT_FOLDER: ${FE_SH} -r ${HG_FOLDER}"
  cd "${GIT_FOLDER}"
  bash ${FE_SH} -r ${HG_FOLDER} || _abort "fast-export failed. Do manually:\n GIT_FOLDER: ${GIT_FOLDER}\nHG_FOLDER: ${HG_FOLDER}\n${FE_SH}"
  git checkout HEAD
  rm -f .hgignore
}

function _push_to_git {
  cd "${GIT_FOLDER}"
  git push -u origin --all || return 1
  git push -u origin --tags || return 1
}

function _retry_push_to_git {
  _echo_err "Pushing to ${GIT_REPO_URL}"
  while ! _push_to_git; do
    sleep 2 || abort "Aborted push"
    _echo_err "\nRetrying push...\n"
  done
}

SCRIPT_NAME=$(basename "${0}")
[[ -z ${2} && -z ${GIT_PREFIX} ]] && _usage
[[ -z ${1} ]] && _usage

HG_REPO_URL="${1}"
REPO_NAME=$(basename ${HG_REPO_URL})
[[ -n ${GIT_PREFIX} ]] && GIT_REPO_URL="${GIT_PREFIX}${REPO_NAME}"
[[ -n ${2} ]] && GIT_REPO_URL="${2}"

#_check_auth_vars
_get_fast_export_script
_create_temp_folders
_clone_hg_repo
_create_git_repo
_fast_export
## _add_git_remote # sollte nicht gebraucht werden
_push_to_git

_echo_err "\n\n"
echo "${GIT_REPO_URL}"

exit 0
