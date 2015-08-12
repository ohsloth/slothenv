#!/usr/bin/env bash

CUEBENV_AUTH_FILE=~/.cuebenv_auth
# CUEB_TRIGGER_URL="https://cueb.io/api/v1/contexts/local"
CUEBENV_TRIGGER_TIMEOUT=3600
CUEB_TRIGGER_URL="https://127.0.0.1:3443/contexts/local"

if [ -z "$CUEBENV_ENV_FILENAME" ]; then
    CUEBENV_ENV_FILENAME=.cueb
fi

if [[ -n "${ZSH_VERSION}" ]]
then __array_offset=0
else __array_offset=1
fi

cuebenv_second_since_lastmod() {
  echo $(( $(date +%s) - $(stat -f%c "$1") ))
}

cuebenv_init() {
  defIFS=$IFS
  IFS=$(echo -en "\n\b")

  typeset target home _file
  typeset -a _files
  target=$1
  home="$(dirname $HOME)"

  _files=( $(
    while [[ "$PWD" != "/" && "$PWD" != "$home" ]]
    do
      _file="$PWD/$CUEBENV_ENV_FILENAME"
      if [[ -e "${_file}" ]]
      then echo "${_file}"
      fi
      builtin cd .. &>/dev/null
    done
  ) )

  _file=${#_files[@]}
  while (( _file > 0 ))
  do
    envfile=${_files[_file-__array_offset]}
    cuebenv_check_authz_and_run "$envfile"
    : $(( _file -= 1 ))
  done

  IFS=$defIFS
}

cuebenv_run() {
  typeset _file
  _file="$(realpath "$1")"
  cuebenv_check_authz_and_run "${_file}"
}

cuebenv_env() {
  builtin echo "cuebenv:" "$@"
}

cuebenv_printf() {
  builtin printf "cuebenv: "
  builtin printf "$@"
}

cuebenv_indent() {
  sed 's/.*/cuebenv:     &/' $@
}

cuebenv_hashline() {
  typeset envfile hash
  envfile=$1
  if which shasum &> /dev/null
  then hash=$(shasum "$envfile" | cut -d' ' -f 1)
  else hash=$(sha1sum "$envfile" | cut -d' ' -f 1)
  fi
  echo "$envfile:$hash"
}

cuebenv_check_authz() {
  typeset envfile hash
  envfile=$1
  hash=$(cuebenv_hashline "$envfile")
  touch $CUEBENV_AUTH_FILE
  \grep -Gq "$hash" $CUEBENV_AUTH_FILE
}

cuebenv_check_authz_and_run() {
  typeset envfile
  envfile=$1
  if cuebenv_check_authz "$envfile"; then
    cuebenv_source "$envfile"
    return 0
  fi
  if [[ -z $MC_SID ]]; then #make sure mc is not running
    cuebenv_env
    cuebenv_env "WARNING:"
    cuebenv_env "This is the first time you are about to source $envfile":
    cuebenv_env
    cuebenv_env "    --- (begin contents) ---------------------------------------"
    cuebenv_indent "$envfile"
    cuebenv_env
    cuebenv_env "    --- (end contents) -----------------------------------------"
    cuebenv_env
    cuebenv_printf "Are you sure you want to allow this? (y/N) "
    read answer
    if [[ "$answer" == "y" ]]; then
      cuebenv_authorize_env "$envfile"
      cuebenv_source "$envfile"
    fi
  fi
}

cuebenv_deauthorize_env() {
  typeset envfile
  envfile=$1
  \cp "$CUEBENV_AUTH_FILE" "$CUEBENV_AUTH_FILE.tmp"
  \grep -Gv "$envfile:" "$CUEBENV_AUTH_FILE.tmp" > $CUEBENV_AUTH_FILE
}

cuebenv_authorize_env() {
  typeset envfile
  envfile=$1
  cuebenv_deauthorize_env "$envfile"
  cuebenv_hashline "$envfile" >> $CUEBENV_AUTH_FILE
}

cuebenv_source() {
  typeset allexport
  allexport=$(set +o | grep allexport)
  set -a
  if [ `cuebenv_second_since_lastmod $1` -gt $CUEBENV_TRIGGER_TIMEOUT ]
  then
      touch $1
      cuebenv_trigger "`cat $1`"
  fi
  eval "$allexport"
}

cuebenv_trigger() {
    source ~/.cuebenv/cred.ini
    curl -XPOST -v -H "x-access-token: ${cueb_api_key}" -H "Content-Type: application/json" \
        $CUEB_TRIGGER_URL -d '{
            "uri": "'$PWD'",
            "keywords": "'$1'"
        }' &>/dev/null
}

cuebenv_cd() {
  if builtin cd "$@"
  then
    cuebenv_init
    return 0
  else
    return $?
  fi
}

cd() {
  cuebenv_cd "$@"
}

cd .
