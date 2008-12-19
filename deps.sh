#!/bin/bash
set -e

BASE="/opt/local/vertebra"
EJABBERD=ejabberd-2.0.2
ERLSOM=erlsom-1.2.1
OTP_VERSION=R12B-5
OTP_SRC=otp_src_$OTP_VERSION
OTP_DOC=otp_doc_man_$OTP_VERSION

# Make sure that what we install is first on the path for other things we
# install.
export PATH="${BASE}/bin:${BASE}/sbin:${PATH}"

if [ -z "$*" ] ; then
  echo "USAGE: $0 [-r | -e | -j | -l]"
  echo "  -a : Install everything"
  echo "  -e : Install Erlang OTP"
  echo "  -j : Install ejabberd Server"
  echo "  -r : Install RubyGems"
  echo "  -x : Install erlsom"
  echo ""
  echo "NOTE: $0 depends on a working build environment,"
  echo "      wget OR curl, ruby, and rubygems."
  echo "NOTE: We currently only install the Erlang stuff in ${BASE},"
  echo "      but gems are installed normally."
  exit 1
fi

### Helper Functions

# Fetches a File Or Uses Existing Copy
# FIXME: Should we resume or do MD5 detection or something?
fetch_file () {
  local URL="$1"
  local FILE=$(basename "${URL}")
  echo "Getting file at ${URL}..."
  if [ -e "${FILE}" ] ; then
    echo "Using existing copy..."
    return
  fi
  if [ ! -z "${CURL}" ] ; then
    "${CURL}" -L -O "${URL}"
  elif [ ! -z "${WGET}" ] ; then
    "${WGET}" "${URL}"
  else
    echo "Unable to find program to fetch ${URL}..."
    exit 1
  fi
}

# Used To Inform User When Running Some Critical Commands
do_echo () {
  echo $@
  $@
}

# Used To Detect Presence Of A Dependency, Failure To Detect Aborts Script
detect () {
  local VAR="$1"
  local CMD="$2"
  local NAME="$3"
  local BIN=""
  if [ ! -z "${!VAR}" ] ; then
    return
  fi
  if BIN=$(which ${CMD}) ; then
    echo "Detected ${NAME} (${CMD})..."
  else
    echo "ERROR: Unable to detect ${NAME} (${CMD})..."
    exit 1
  fi
  readonly ${VAR}="${BIN}"
}

# Same As Above, But Failure Just Issues A Warning
detect_opt () {
  local VAR="$1"
  local CMD="$2"
  local NAME="$3"
  local BIN=""
  if [ ! -z "${!VAR}" ] ; then
    return
  fi
  if BIN=$(which ${CMD}) ; then
    echo "Detected ${NAME} (${CMD})..."
  else
    echo "Unable to detect ${NAME} (${CMD})..."
    return
  fi
  readonly ${VAR}="${BIN}"
}

# Installs a Gem
install_gem () {
  local GM
  while [ ! -z "$1" ] ; do
    GM=$1
    echo "Installing Missing Gem (${GM}).."
    if gem list "${GM}" | grep -qs "${GM}" ; then
      echo "Gem ${GM} already installed..."
    else
      gem install ${GM}
    fi
    shift
  done
}

### Actual Detection Process

# OS Detection
OS=`uname -s`
if [ "$OS" == "Linux" ] ; then
  echo "Detected Linux..."
elif [ "$OS" == "Darwin" ] ; then
  echo "Detected MacOS X..."
else
  echo "ERROR: Unrecognized Operating System"
  exit 1
fi

# Detect Utilities To Fetch Files
detect_opt CURL curl "cURL Utility"
detect_opt WGET wget "Wget Utility"

### Detect / Build / Install Scripting
# Note, that these detection functions are different than detect / detect_opt.
# These don't detect dependencies, they detect if they are attempting to
# clobber an existing installation.  As such, they have very different return
# and exit semantics, and care should be made in distinguishing them.

# Ruby Detection: Detects Ruby / RubyGems, but forces gem installation always
detect_rb () {
  detect RUBY ruby "Ruby"
  detect GEM gem "Ruby Gems"
  # There's no harm that will come from always installing the ruby gems.
  return 1
}

detect_erl () {
  local ERL=$(which erl)

  if [ -x "$ERL" ]; then
      # This is based on the observation that the erts point release seems to
      # always be the same as the OTP pont release. So for R12B-4 it'll be x.y.4.
      local V=$($ERL -noshell \
          -eval "io:format(\"~s-\", [erlang:system_info(otp_release)])" \
          -eval "io:format(hd(lists:reverse(string:tokens(erlang:system_info(version),\".\"))))" \
          -s init stop)
      return $([ "$V" == "$OTP_VERSION" ])
  else
      return 1
  fi
}

detect_ejd () {
  local CTL=$(which ejabberdctl)
  return $([ -x "$CTL" ])
}

detect_erlsom () {
  local ERL=$(which erl)
  local LIB=$($ERL -noshell -eval "io:format(code:lib_dir())" -s init stop)
  local BEAM=$($ERL -noshell -eval "io:format(code:which(erlsom))" -s init stop)
  return $([ "$(dirname $BEAM)" == "$LIB/$ERLSOM/ebin" ])
}

build_rb () {
  return
}

build_erl () {
  echo Building Erlang OTP...
  fetch_file http://erlang.org/download/$OTP_SRC.tar.gz
  fetch_file http://erlang.org/download/$OTP_DOC.tar.gz
  rm -rf $OTP_SRC
  tar zxf $OTP_SRC.tar.gz
  pushd $OTP_SRC
  if [ "${OS}" == "Darwin" ] ; then
    HIPE="--disable-hipe"
  else
    HIPE="--enable-hipe"
  fi
  ./configure --prefix="${BASE}" $HIPE --enable-smp --enable-threads
  make
  popd
}

build_ejd () {
  echo Building Erlang Jabber Daemon...
  fetch_file http://www.process-one.net/downloads/ejabberd/2.0.2/$EJABBERD.tar.gz
  rm -rf $EJABBERD
  tar zxf $EJABBERD.tar.gz
  pushd $EJABBERD/src
  ./configure --prefix="${BASE}" --with-erlang="${BASE}" --disable-mod_irc --disable-mod_pubsub --disable-eldap
  make
  popd
}

build_erlsom () {
  echo Building erlsom...
  fetch_file http://downloads.sourceforge.net/erlsom/$ERLSOM.tar.gz
  rm -rf $ERLSOM
  mkdir $ERLSOM
  pushd $ERLSOM
  tar zxvf ../$ERLSOM.tar.gz
  # Fix line endings
  for i in `find . -type f`; do
    sed -i -e 's/$//' $i
  done
  sh configure --prefix="${BASE}" --with-erlang="${BASE}"
  make
  popd
}

install_rb () {
  echo Installing RubyGems...

  install_gem rspec facets xmpp4r open4 thor rr hoe
}

install_erl () {
  echo Installing Erlang OTP...
  pushd $OTP_SRC
  make install
  popd

  tar zxvf $OTP_DOC.tar.gz -C $BASE/lib/erlang
}

install_ejd () {
  echo Installing Erlang Jabber Daemon...
  pushd $EJABBERD/src
  make install
  popd

  # If we do not have a cookie, the the erlang command below will create it.
  [ -r $HOME/.erlang.cookie ] || local CREATED_COOKIE=true

  local COOKIE=$BASE/var/lib/ejabberd/.erlang.cookie
  # Make sure that ejabberd will use the same cookie we use.
  erl -sname __install -noshell \
    -eval 'io:format("~s", [atom_to_list(erlang:get_cookie())])' \
    -s init stop \
    > $COOKIE
  chmod 600 $COOKIE

  # If we created the cookie and we are running via sudo (a likely case), chown
  # the cookie file to the sudo user so that we can read it when we aren't
  # running via sudo.
  if [ "$CREATED_COOKIE" == "true" ] && [ "$SUDO_USER" != "" ]; then
    chown $SUDO_USER $HOME/.erlang.cookie
  fi
}

install_erlsom () {
  echo Installing Erlsom...
  pushd $ERLSOM
  make install
  popd
}

# General Installation Scripting
do_part () {
  local PART=$1
  local NAME=$2
  if ! detect_$PART ; then
    build_$PART
    install_$PART
    echo $NAME installed.
  else
    echo $NAME detected.
  fi
}

do_configure () {
  pushd vertebra-erl
  make install-config
  popd

  JIDS="herault entrepot cavalcade
        vertebra-client rd00-n00 rd00-s00000"
  if detect_ejd; then
    do_echo ejabberdctl start
    for user in $JIDS; do
      # There are some timing issues unless we put a pause in between these
      # commands. This is basically simulating the time between running each
      # command by hand.
      sleep 5
      do_echo ejabberdctl unregister $user localhost
      sleep 5
      do_echo ejabberdctl register $user localhost testing
    done
    do_echo ejabberdctl stop
  fi
}

# Command Line Handlers
do_rb () {
  do_part rb "Ruby Gems"
}

do_erl () {
  do_part erl "Erlang OTP"
}

do_ejd () {
  do_part ejd "ejabberd"
}

do_erlsom () {
  do_part erlsom "erlsom"
}

if [ "$1" == "-r" ] ; then
  do_rb
  exit 0
fi

if [ "$1" == "-e" ] ; then
  do_erl
  exit 0
fi

if [ "$1" == "-j" ] ; then
  do_ejd
  exit 0
fi

if [ "$1" == "-x" ] ; then
  do_erlsom
  exit 0
fi

if [ "$1" == "-a" ] ; then
  do_ejd
  do_erl
  do_erlsom
  do_rb
  exit 0
fi
