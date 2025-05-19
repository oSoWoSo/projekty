#!/bin/bash
# vim: ft=sh ts=2 sw=2 sts=2 et

# vbm - vb-linux management utility for
# XBPS, the X Binary Package System
# original author: Armin Jenewein <a@m2m.pm>, GitHub: @netzverweigerer
# a lot used from: Dave Eddy <dave@daveeddy.com>, GitHub: @bahamas10
# this fork: zenobit <zen@osowoso.xyz>, codeberg.org: @oSoWoSo
# For more information about XBPS, see:
# https://github.com/voidlinux/xbps

# Released under the terms of the GNU general public license, version 3+
# see LICENSE file for license information.

# set version number
version="1.0"
# enable verbosity, by default
verbose=true
# program name
progname=${0##*/}

# VBM color definitions
numcolorok=2
numcolorfail=1
numcolorlogo=2
numcolorheader=3
numcolortext=4
numcolorgray=8
numcolorpkgcount=7
numcolordarkgray=11
numcolorbrackets=1

# enable or disable colors based on the argument given, i.e.:
# setcolors on   # colors on
# setcolors off  # colors off
# setcolors auto # colors on or off depending on environment
declare -A COLORS
setcolors() {
  local opt=$1

  # determine if colors should be enabled or not
  if [[ $opt == auto ]]; then
    # if stdout is a TTY and the TERM looks like it supports color enable colors
    if [[ -t 1 && $TERM == *color* ]]; then
      opt='on'
    else
      opt='off'
    fi
  fi

  case "$opt" in
    on)
      local i
      for i in {1..11}; do
        if [[ -n ${COLORS[$i]} ]]; then
          continue
        fi
        COLORS[$i]=$(tput setaf "$i")
      done
      colorbrackets=${COLORS[$numcolorbrackets]}
      colordarkgray=${COLORS[$numcolordarkgray]}
      colorfail=${COLORS[$numcolorfail]}
      colorgray=${COLORS[$numcolorgray]}
      colorheader=${COLORS[$numcolorheader]}
      colorlogo=${COLORS[$numcolorlogo]}
      colorok=${COLORS[$numcolorok]}
      colorpkgcount=${COLORS[$numcolorpkgcount]}
      colortext=${COLORS[$numcolortext]}
      colorreset=$(tput sgr0)
    ;;
    off)
      colorbrackets=
      colordarkgray=
      colorfail=
      colorgray=
      colorheader=
      colorlogo=
      colorok=
      colorpkgcount=
      colortext=
      colorreset=
      unset COLORS
      declare -A COLORS
    ;;
    *)
      rmsg 255 "unknown color option: '$opt'"
      exit 255
    ;;
  esac
}

# print the logo with brackets colorized
getlogo() {
  printf '%s[%s%s%s]%s' \
    "$colorbrackets" \
    "$colorlogo" "$progname" \
    "$colorbrackets" \
    "$colorreset"
}

# prints a message (with vbm-prefix)
msg() {
  local logo=$(getlogo)
  local newline=true

  if [[ $1 == '-n' ]]; then
    newline=false
    shift
  fi

  printf '%s %s%s%s' "$logo" "$colortext" "$*" "$colorreset"
  $newline && echo
}

# rmsg - same (but colorized based on return status passed via $1)
rmsg() {
  local code=$1
  shift

  local logo=$(getlogo)
  local statuscolor

  if ((code == 0)); then
    statuscolor=$colorok
  else
    statuscolor=$colorfail
  fi

  printf '%s %s%s%s\n' "$logo" "$statuscolor" "$*" "$colorreset"
}

banner() {
  echo -n "$colorlogo"
  echo ' __ __/|__ _ __  '
  printf " \\ V / '_ \\ '  \ "
  echo -n "$colorgray"
  echo " $progname - XBPS package management helper"
  echo -n "$colorlogo"
  echo -n '  \_/|_,__/_|_|_\'
  echo -n "$colorgray"
  echo ' Source: https://codeberg.org/oSoWoSo/vbm'
  echo -n "$colorlogo"
  echo -n "$colorreset"
}

version() {
  banner
  echo
  msg "${colorpkgcount}$progname - Version: $version (GPLv3+)"
  msg "${colorpkgcount}original author: Armin Jenewein <a@m2m.pm>"
  msg "https://github.com/netzverweigerer/vpm"
  msg "${colorpkgcount}a lot used from: Dave Eddy <dave@daveeddy.com>"
  msg "https://github.com/bahamas10/vpm"
  msg "${colorpkgcount}this fork: zenobit <zen@osowoso.xyz>"
  msg "https://codeberg.org/oSoWoSo/vbm"
  msg "${colorpkgcount}XBPS version: $(xbps-query -v --version | sed 's/GIT: UNSET//')"
}

# check if we have UID 0, exit otherwise
rootcheck() {
  if [[ $EUID -gt 0 ]]; then
    msg "$(tput setaf 1)This operation needs super-user privileges.$(tput sgr 0)"
    SUDO=sudo
  else
    SUDO=''
  fi
}

t() {
  if [[ -n $show_translations ]]; then
    tput setaf 242
    echo '                             ' "$@"
    echo
    tput setaf 109
  fi
}

wrapcommand() {
  local cmd ret
  cmd=("$@")

  echo "$colortext(${cmd[*]}):$colorreset"

  "${cmd[@]}"
  ret=$?

  rmsg "$ret" "[${cmd[*]}], return code was: $ret"
  exit "$ret"
}

usage() {
  echo
  version
  echo
  echo "${colorheader}USAGE:
 ${colorpkgcount}${progname} ${colortext}[OPTIONS] ${colorok}[SUBCOMM${colorfail}ANDS] ${colorpkgcount}[<ARGS>]

 ${colorheader} OPTIONS : 
 ${colortext}--color=<yes|no|auto> ${colorgray}Enable/Disable colorized output (default: auto)
 ${colortext}--help                ${colorgray}(same as: help) show usage
 ${colortext}--slim                ${colorgray}(same as: slim) show usage for small screens
 ${colortext}--help-pager          ${colorgray}(same as: helppager)
 ${colortext}--show-translations   ${colorgray}Show ${colorpkgcount}XBPS${colorgray} command translations for $colorpkgcount$progname$colorgray sub-commands
 ${colortext}--verbose             ${colorgray}Show ${colorpkgcount}XBPS${colorgray} command translations during execution

 ${colorheader}    SUBCOMMANDS : 
 ${colorok}(long)        ${colorfail}(short)${colorpkgcount}   <ARGS>"
  echo " ${colorok}sync              ${colorfail}(S)          ${colorgray}Synchronize remote repository data"
  t "xbps-install -S"
  echo " ${colorok}update            ${colorfail}(u)          ${colorgray}Update the system"
  t "xbps-install -Suv"
  echo " ${colorok}search            ${colorfail}(s)    ${colorpkgcount}<pkg> ${colorgray}Search for package"
  t "xbps-query -v -Rs"
  echo " ${colorok}syncsearch       ${colorfail}(Ss)          ${colorgray}Fetch repodata and search for package"
  t "xbps-query -v -MRs"
  echo " ${colorok}about             ${colorfail}(a)    ${colorpkgcount}<pkg> ${colorgray}Show information about <package>"
  t "xbps-query -v -R"
  echo " ${colorok}install           ${colorfail}(i) ${colorpkgcount}<pkg(s)> ${colorgray}Install <package(s)>"
  t "xbps-install"
  echo " ${colorok}remove           ${colorfail}(rm) ${colorpkgcount}<pkg(s)> ${colorgray}Remove <package(s)> from the system"
  t "xbps-remove -v "
  echo " ${colorok}filelist         ${colorfail}(fl)    ${colorpkgcount}<pkg> ${colorgray}Show file-list of <package>"
  t "xbps-query -v -R -f"
  echo " ${colorok}deps              ${colorfail}(d)    ${colorpkgcount}<pkg> ${colorgray}Show dependencies for <package>"
  t "xbps-query -v -R -x"
  echo " ${colorok}reverse          ${colorfail}(rd)    ${colorpkgcount}<pkg> ${colorgray}Show reverse dependendies of <package>"
  t "xbps-query -v -R -X"
  echo " ${colorok}searchlib        ${colorfail}(sl)    ${colorpkgcount}<pkg> ${colorgray}Search for package (64bit only)"
  t "xbps-query -v -Rs"
  echo " ${colorok}searchfile       ${colorfail}(sf)   ${colorpkgcount}<file> ${colorgray}Search for package containing <file> (local)"
  t "xbps-query -v -o \"*/$1\""
  echo " ${colorok}whatprovides     ${colorfail}(wp)   ${colorpkgcount}<file> ${colorgray}Search for package containing <file>"
  t "xlocate ${colorpkgcount}<pkg>"
  echo " ${colorok}list             ${colorfail}(ls)          ${colorgray}List installed packages"
  t "xbps-query -v -l"
  echo " ${colorok}listw            ${colorfail}(lw)          ${colorgray}List installed packages without their version"
  t "xbps-query -l | awk '{ print $2 }' | xargs -n1 xbps-uhelper getpkgname"
  echo " ${colorok}listalternatives ${colorfail}(la)          ${colorgray}List alternative candidates"
  t "xbps-alternatives -l"
  echo " ${colorok}listrepos        ${colorfail}(lr)          ${colorgray}List configured repositories"
  echo " ${colorok}repolist         ${colorfail}(rl)          ${colorgray}Alias for listrepos"
  t "xbps-query -v -L"
  echo " ${colorok}addrepo          ${colorfail}(ad)   ${colorpkgcount}<ARGS> ${colorgray}Add an additional repository"
  t "xbps-install ${colorpkgcount}<ARGS>"
  echo " ${colorok}devinstall       ${colorfail}(di) ${colorpkgcount}<pkg(s)> ${colorgray}Install <package>${colorgray} and devel-<package(s)>"
  t "xbps-install <package> <package>${colorgray}-devel"
  echo " ${colorok}reconfigure      ${colorfail}(rc)    ${colorpkgcount}<pkg> ${colorgray}Re-configure installed <package>"
  t "xbps-reconfigure -v"
  echo " ${colorok}forceinstall     ${colorfail}(fi) ${colorpkgcount}<pkg(s)> ${colorgray}Force installation of <package(s)>"
  t "xbps-install -f"
  echo " ${colorok}setalternative   ${colorfail}(sa) ${colorpkgcount}<pkg(s)> ${colorgray}Set alternative for <package>"
  t "xbps-alternatives -s"
  echo " ${colorok}removerecursive  ${colorfail}(rr) ${colorpkgcount}<pkg(s)> ${colorgray}Remove package(s) with dependencies"
  t "xbps-remove -v -R"
  echo " ${colorok}cleanup          ${colorfail}(cl)          ${colorgray}Remove obsolete packages in cachedir"
  t "xbps-remove -v -O"
  echo " ${colorok}autoremove       ${colorfail}(ar)          ${colorgray}Remove orphaned packages"
  t "xbps-remove -v -o"
  echo
  echo "${colorpkgcount}XBPS${colorheader} COMPATIBILITY COOLNESS:"
  echo -n "$colorgray"
  f=(/usr/sbin/xbps-*)
  echo "$colorpkgcount$progname$colorgray also understands all unknown ${colorpkgcount}XBPS${colorgray} sub-commands, too:"
  echo -n "Example: "
  selected=${f[$RANDOM % ${#f[@]}]}
  echo "$colorpkgcount$progname$colorok ${selected##*-}$colorreset ${colorpkgcount}<ARGS> $colorgray- see also: /usr/sbin/xbps-*"
  echo -n "$colorreset"
}

usage_slim() {
  echo
  version
  echo
  echo "${colorheader}USAGE:
 ${colorpkgcount}${progname} ${colortext}[OPTIONS] ${colorok}[SUBCOMM${colorfail}ANDS] ${colorpkgcount}[<ARGS>]

${colorheader}OPTIONS : 
${colortext}--color=<yes|no|auto>
  ${colorgray}Enable/Disable colorized output (default: auto)
${colortext}--help
  ${colorgray}(same as: help) show usage
${colortext}--slim
  ${colorgray}(same as: slim) show usage for small screens
${colortext}--help-pager
  ${colorgray}(same as: helppager)
${colortext}--show-translations
  ${colorgray}Show ${colorpkgcount}XBPS${colorgray} command translations for $colorpkgcount$progname$colorgray sub-commands
${colortext}--verbose
  ${colorgray}Show ${colorpkgcount}XBPS${colorgray} command translations during execution

 ${colorheader}   SUBCOMMANDS : 
${colorok}(long)        ${colorfail}(short)${colorpkgcount} <ARGS> 
${colorok}about             ${colorfail}(a) ${colorpkgcount}<pkg>
  ${colorgray}Show information about <package>"
  t "xbps-query -v -R"
  echo "${colorok}filelist         ${colorfail}(fl) ${colorpkgcount}<pkg>
  ${colorgray}Show file-list of <package>"
  t "xbps-query -v -R -f"
  echo "${colorok}deps              ${colorfail}(d) ${colorpkgcount}<pkg>
  ${colorgray}Show dependencies for <package>"
  t "xbps-query -v -R -x"
  echo "${colorok}reverse          ${colorfail}(rd) ${colorpkgcount}<pkg>
  ${colorgray}Show reverse dependendies of <package>"
  t "xbps-query -v -R -X"
  echo "${colorok}search            ${colorfail}(s) ${colorpkgcount}<pkg>
  ${colorgray}Search for package"
  t "xbps-query -v -Rs"
  echo "${colorok}searchlib        ${colorfail}(sl) ${colorpkgcount}<pkg>
  ${colorgray}Search for package (64bit only)"
  t "xbps-query -v -Rs"
  echo "${colorok}searchfile       ${colorfail}(sf) ${colorpkgcount}<file>
  ${colorgray}Search for package containing <file> (local)"
  t "xbps-query -v -o \"*/$1\""
  echo "${colorok}whatprovides     ${colorfail}(wp) ${colorpkgcount}<file>
  ${colorgray}Search for package containing <file>"
  t "xlocate ${colorpkgcount}<pkg>"
  echo "${colorok}list             ${colorfail}(ls)
  ${colorgray}List installed packages"
  t "xbps-query -v -l"
  echo "${colorok}listw            ${colorfail}(lw)
  ${colorgray}List installed packages without version"
  t "xbps-query -l | awk '{ print $2 }' | xargs -n1 xbps-uhelper getpkgname"
  echo "${colorok}listalternatives ${colorfail}(la)
  ${colorgray}List alternative candidates"
  t "xbps-alternatives -l"
  echo "${colorok}listrepos        ${colorfail}(lr)
  ${colorgray}List configured repositories"
  echo "${colorok}repolist         ${colorfail}(rl)
  ${colorgray}Alias for listrepos"
  t "xbps-query -v -L"
  echo "${colorok}sync              ${colorfail}(S)
  ${colorgray}Synchronize remote repository data"
  t "xbps-install -S"
  echo "${colorok}update            ${colorfail}(u)
  ${colorgray}Update the system"
  t "xbps-install -Suv"
  echo "${colorok}addrepo          ${colorfail}(ad) ${colorpkgcount}<ARGS>
  ${colorgray}Add an additional repository"
  t "xbps-install ${colorpkgcount}<ARGS>"
  echo "${colorok}install           ${colorfail}(i) ${colorpkgcount}<pkg(s)>
  ${colorgray}Install <package(s)>"
  t "xbps-install"
  echo "${colorok}devinstall       ${colorfail}(di) ${colorpkgcount}<pkg(s)>
  ${colorgray}Install <package> and devel-<package>(s)"
  t "xbps-install <package> <package>-devel"
  echo "${colorok}reconfigure      ${colorfail}(rc) ${colorpkgcount}<pkg>
  ${colorgray}Re-configure installed <package>"
  t "xbps-reconfigure -v"
  echo "${colorok}forceinstall     ${colorfail}(fi) ${colorpkgcount}<pkg(s)>
  ${colorgray}Force installation of <package(s)>"
  t "xbps-install -f"
  echo "${colorok}setalternative   ${colorfail}(sa) ${colorpkgcount}<pkg(s)>
  ${colorgray}Set alternative for <package>"
  t "xbps-alternatives -s"
  echo "${colorok}remove           ${colorfail}(rm) ${colorpkgcount}<pkg(s)>
  ${colorgray}Remove <package(s)>${colorgray} from the system"
  t "xbps-remove -v "
  echo "${colorok}removerecursive  ${colorfail}(rr) ${colorpkgcount}<pkg(s)>
  ${colorgray}Remove package(s) with dependencies"
  t "xbps-remove -v -R"
  echo "${colorok}cleanup          ${colorfail}(cl)
  ${colorgray}Remove obsolete packages in cachedir"
  t "xbps-remove -v -O"
  echo "${colorok}autoremove       ${colorfail}(ar)
  ${colorgray}Remove orphaned packages"
  t "xbps-remove -v -o"
  echo "$colorheader"
  echo "${colorpkgcount}XBPS${colorgray} COMPATIBILITY COOLNESS:"
  echo -n "$colorgray"
  f=(/usr/sbin/xbps-*)
  echo "$colorpkgcount$progname$colorgray understands ${colorpkgcount}XBPS${colorgray} sub-commands"
  echo -n "Example: "
  selected=${f[$RANDOM % ${#f[@]}]}
  echo "$colorpkgcount$progname$colorok ${selected##*-}$colorreset ${colorpkgcount}<ARGS> $colorgray
  see also: /usr/sbin/xbps-*$colorreset"
}

setcolors auto
case "$1" in
  --color=true|--color=yes|--color=on)
    setcolors on
    shift
  ;;
  --color=auto)
    setcolors auto
    shift
  ;;
  --color=false|--color=off|--color=no)
    setcolors off
    shift
  ;;
  --verbose=true)
    shift
    verbose=true
  ;;
  --show-translations)
    shift
    show_translations=1
  ;;
  --help)
    shift
    usage
    exit 255
  ;;
  --slim)
    shift
    usage_slim
  ;;
  --help-pager)
    shift
    "$0" --color=off --help | less
  ;;
  --*)
    msg "Unknown option: $1 (try: $progname --help)"
    exit 1
  ;;
esac

if [[ -z $1 ]]; then
  usage
  exit 0
fi

cmd=$1
if [[ $arg =~ --.* ]]; then
  cmd=${arg:2}
fi
shift

case "$cmd" in

  about|a)
    wrapcommand xbps-query -v -R "$@"
  ;;

  filelist|fl|listfiles)
    wrapcommand xbps-query -v -R -f "$@"
  ;;

  deps|dep|dependencies|d)
    wrapcommand xbps-query -v -R -x "$@"
  ;;

  reverse|rd)
    msg "Reverse dependencies for $* "
    wrapcommand xbps-query -v -R -X "$@"
  ;;

  searchfile|sf)
    msg 'searchfile '
    wrapcommand xbps-query -v -o "*/$1"
  ;;

  remotesearchfile|rsf)
    msg 'remotesearchfile '
    wrapcommand xbps-query -R -v -o "*/$1"
  ;;

  list|ls)
    msg 'Installed packages: '

    count=0
    while read -r _ pkg _; do
      ((count++))
      pkgname=${pkg%-*}
      version=${pkg##*-}

      printf '%s%d %s%s %s (%s%s%s) [%s%s%s]%s\n' \
        "$colorpkgcount" "$count" \
        "$colortext" "$pkgname" \
        "$colorbrackets" \
        "$colorgray" "$version" \
        "$colorbrackets" \
        "$colordarkgray" "$pkg" \
        "$colorbrackets" \
        "$colorreset"
    done < <(xbps-query -v -l)
  ;;

  listw|lw)
    xbps-query -l | awk '{ print $2 }' | xargs -n1 xbps-uhelper getpkgname
  ;;

  listalternative|listalternatives|la)
    wrapcommand xbps-alternatives -l "$@"
  ;;

  setalternative|setalternatives|sa)
    rootcheck
    wrapcommand xbps-alternatives -s "$@"
    echo
  ;;

  repolist|listrepos|rl|lr)
    code=0
    msg "Configured repositories (xbps-query -v -L): "

    xbps-query -v -L
    ret=$?
    ((ret == 0)) || code=1
    rmsg "$ret" "[xbps-query -v -L] return code: $ret"

    echo

    msg "Available sub-repositories (xbps-query -v -Rs void-repo): "
    xbps-query -v -Rs void-repo
    ret=$?
    ((ret == 0)) || code=1
    rmsg "$ret" "[xbps-query -v -Rs void-repo] return code: $ret"

    echo

    msg "Use \"$progname addrepo <repository>\" to add a sub-repository."
    echo

    exit "$code"
  ;;

  addrepo|ad)
    rootcheck
    echo
    if (($# < 1)); then
      rmsg 255 "ERROR: install: argument missing, try --help."
      exit 1
    fi
    code=0
    for repo in "$@"; do
      msg "Adding repository: $repo"
      $SUDO xbps-install "$repo"
      ret=$?
      ((ret == 0)) || code=1
      rmsg "$ret" "[xbps-install $arg] return code: $ret"

      msg "Synchronizing remote repository data (xbps-install -S): "
      $SUDO xbps-install -S
      ret=$?
      ((ret == 0)) || code=1
      rmsg "$ret" "[xbps-install -S] return code: $ret"
    done

    exit "$code"
    ;;

  sync|S)
    rootcheck
    msg 'Synchronizing remote repository data '
    echo
    wrapcommand "$SUDO" xbps-install -S "$@"
  ;;

  install|i)
    rootcheck
    if (($# < 1)); then
      rmsg 255 "ERROR: install: argument missing, try --help."
      exit 1
    fi

    msg "Installing packages: $* "
    echo
    wrapcommand "$SUDO" xbps-install "$@"
  ;;

  yesinstall)
    rootcheck
    if (($# < 1)); then
      rmsg 255 "ERROR: install: argument missing, try --help."
      exit 1
    fi
    msg "Installing packages (assumed yes): $* "
    echo
    wrapcommand "$SUDO" xbps-install -y "$@"
  ;;

  devinstall)
    rootcheck
    if (($# < 1)); then
      rmsg 255 "ERROR: devinstall: argument missing, try --help."
      exit 1
    fi

    args=("$@")
    code=0

    msg "devinstall: Packages will be installed one-by-one"
    msg "Use \"forceinstall\" to override this if you know what you're doing."
    msg "(Note: forceinstall won't install -devel packages)"
    for arg in "${args[@]}"; do
      msg "Installing package: $arg (xbps-install $arg) ..."
      $SUDO xbps-install "$arg"
      ret=$?
      ((ret == 0)) || code=1
      rmsg "$ret" "[xbps-install $arg] return code: $ret"

      msg "installing devel package (${arg}-devel):"
      $SUDO xbps-install "${arg}-devel"
      ret=$?
      ((ret == 0)) || code=1
      rmsg "$ret" "[xbps-install ${arg}-devel] return code: $ret"
    done

    exit "$code"
  ;;

  forceinstall|fi)
    rootcheck
    msg "Force-Installing Package(s): $* "
    echo
    wrapcommand "$SUDO" xbps-install -f "$@"
  ;;

  remove|rm)
    rootcheck
    msg "Removing package(s): $* "
    echo
    wrapcommand "$SUDO" xbps-remove -v "$@"
  ;;

  removerecursive|rr)
    rootcheck
    msg "Removing package(s) recursively: $* "
    echo
    wrapcommand "$SUDO" xbps-remove -v -R "$@"
  ;;

  reconfigure|rc)
    rootcheck
    msg 'reconfigure: Re-configuring package(s) '
    echo
    wrapcommand "$SUDO" xbps-reconfigure -v "$@"
  ;;

  autoremove|ar)
    rootcheck
    msg 'autoremove: Removing orphaned packages '
    echo
    wrapcommand "$SUDO" xbps-remove -v -o
  ;;

  update|upgrade|up|u)
    rootcheck
    msg 'Running system update '
    echo
    $SUDO xbps-install -Suv
    if [[ $? == 16 ]]; then
      msg "$(tput setaf 1)Updating xbps $(tput sgr 0)"
      $SUDO xbps-install -u xbps
      wrapcommand "$SUDO" xbps-install -Suv
    else
      if [[ $? == 1 ]]; then
        msg 'Your system is up to date.'
      else
        msg $? 'Something goes wrong!'
      fi
    fi
    msg 'Checking if something need restart...'
    echo
    xcheckrestart
  ;;

  syncsearch|Ss)
    msg "Syncing and searching for: $* "
    wrapcommand xbps-query -v -MRs "$*"
  ;;

  search|s)
    msg "Searching for: $* "
    wrapcommand xbps-query -v -Rs "$*"
  ;;

# TODO: instead of grep use proper command
  searchlib|sl)
    msg "Searching for: $* "
    wrapcommand xbps-query -v -Rs "$*" | grep -v 32bit
  ;;

  cleanup|clean|cl)
    msg 'Remove obsolete packages in cachedir '
    rootcheck
    echo
    wrapcommand "$SUDO" xbps-remove -v -O "$@"
  ;;

  h|help|-h|--help)
    usage
  ;;

  slim|--slim)
    usage_slim
  ;;

  helppager|help-pager|hp)
    pager=$PAGER
    if [[ -z $pager ]]; then
      if command -v less &>/dev/null; then
        pager=less
      else
        pager=more
      fi
    fi

    "$0" --color=off help | $pager
    exit 0
  ;;

  version|v)
    version
    exit 0
  ;;

  whatprovides|wp)
    if ! command -v xlocate &>/dev/null; then
      rmsg 255 "xlocate not found. Try installing the xtools package."
      exit 1
    fi

    msg "relaying to xlocate - use xlocate -S to (re-)build cached DB. "
    wrapcommand xlocate "$@"
  ;;

  ''|*)
    xbpscmd="xbps-$cmd"
    if ! command -v "$xbpscmd" &>/dev/null; then
      rmsg 255 "Unrecognized $progname subcommand: $cmd (and $xbpscmd does not exist) - Try: $progname help"
      echo
      exit 1
    fi

    # xbps-<subcommand> found
    msg "relaying to ${colorpkgcount}XBPS${colorgray}: "
    wrapcommand "$xbpscmd" "$@"
  ;;
esac

exit 0
# enjoy and make better if you can...
