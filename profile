# Copyright (C) 2001, 2002  Earnie Boyd  <earnie@users.sf.net>
# This file is part of the Minimal SYStem.
#   http://www.mingw.org/msys.shtml
#
#         File:	profile
#  Description:	Shell environment initialization script
# Last Revised:	2002.05.04

if [ -z "$MSYSTEM" ]; then
  MSYSTEM=MINGW32
fi

# My decision to add a . to the PATH and as the first item in the path list
# is to mimick the Win32 method of finding executables.
#
# I filter the PATH value setting in order to get ready for self hosting the
# MSYS runtime and wanting different paths searched first for files.
if [ $MSYSTEM == MINGW32 ]; then
  export PATH=".:/usr/local/bin:/mingw/bin:/bin:$PATH"
else
  export PATH=".:/usr/local/bin:/bin:/mingw/bin:$PATH"
fi

# strip out cygwin paths from PATH
case "$PATH" in
*/cygwin/*)
	export PATH=$(p=$(echo $PATH | tr ":" "\n" | grep -v "/cygwin/" | tr "\n" ":"); echo ${p%:})
	;;
esac

if [ -z "$USERNAME" ]; then
  LOGNAME="`id -un`"
else
  LOGNAME="$USERNAME"
fi

# Set up USER's home directory
if [ -z "$HOME" -o ! -d "$HOME" ]; then
  HOME="$HOMEDRIVE$HOMEPATH"
  if [ -z "$HOME" -o ! -d "$HOME" ]; then
    HOME="$USERPROFILE"
  fi
fi

if [ ! -d "$HOME" ]; then
	printf "\n\033[31mERROR: HOME directory '$HOME' doesn't exist!\033[m\n\n"
	echo "This is an error which might be related to msysGit issue 108."
	echo "You might want to set the environment variable HOME explicitly."
	printf "\nFalling back to \033[31m/ ($(cd / && pwd -W))\033[m.\n\n"
	HOME=/
fi

# normalize HOME to unix path
HOME="$(cd "$HOME" ; pwd)"

export PATH="$HOME/bin:$PATH"

export GNUPGHOME=~/.gnupg

if [ -z "$MAGIC" ]; then
  magicfile=$(cd / && pwd -W)'/mingw/share/misc/magic.mgc'
  test -f "$magicfile" && export MAGIC="$magicfile"
fi

if [ "x$HISTFILE" == "x/.bash_history" ]; then
  HISTFILE=$HOME/.bash_history
fi

if [ -e ~/.inputrc ]; then
    export INPUTRC=~/.inputrc
else
    export INPUTRC=/etc/inputrc
fi

case "$LS_COLORS" in
*rs*)
	# Our ls may ot handle LS_COLORS inherited in a Wine process
	unset LS_COLORS;;
esac

export HOME LOGNAME MSYSTEM HISTFILE

for i in /etc/profile.d/*.sh ; do
  if [ -f $i ]; then
    . $i
  fi
done

export MAKE_MODE=unix

# Git specific stuff
test -e /bin/git.exe -o -e /git/git.exe || {
	echo
	echo -------------------------------------------------------
	echo "Building and Installing Git"
	echo -------------------------------------------------------

	cd /git &&
	make install

	case $? in
	0)
		MESSAGE="You are in the git working tree, and all is ready for you to hack."
	;;
	*)
		MESSAGE="Your build failed...  Please fix it, and give feedback on the Git list."
	esac

	test -d /installer-tmp && rm -rf /installer-tmp

	cat <<EOF


-------------------------
Hello, dear Git developer.

This is a minimal MSYS environment to work on Git.

$MESSAGE

EOF
}

# let's make sure that the post-checkout hook is installed
test -d /.git && test ! -x /.git/hooks/post-checkout &&
test -x /share/msysGit/post-checkout-hook &&
mkdir -p /.git/hooks &&
cp /share/msysGit/post-checkout-hook /.git/hooks/post-checkout

test -f /etc/motd && sed "s/\$MESSAGE/$MESSAGE/" < /etc/motd
test -x /share/msysGit/initialize.sh -a ! -d /.git &&
cat << EOF

It appears that you installed msysGit using the full installer.
To set up the Git repositories, please run /share/msysGit/initialize.sh
EOF

case ":$PATH:" in
*:/cmd:*|*:/bin:*) ;;
*)
	cat << EOF

In order to use Git from cmd.exe:
1. Add c:\msysgit\cmd to cmd's PATH
2. DON'T add c:\msysgit\bin or c:\msysgit\mingw\bin to cmd's PATH
Commands like 'git add' will work from cmd.exe now.
Commands like 'git-add' will NOT work. Add more wrappers as appropriate.
EOF
esac


. /etc/git-completion.bash
[ -r /etc/git-prompt.sh ] && . /etc/git-prompt.sh

# non-printable characters must be enclosed inside \[ and \]
PS1='\[\033]0;$MSYSTEM:${PWD//[^[:ascii:]]/?}\007\]' # set window title
PS1="$PS1"'\n'                 # new line
PS1="$PS1"'\[\033[32m\]'       # change color
PS1="$PS1"'\u@\h '             # user@host<space>
PS1="$PS1"'\[\033[33m\]'       # change color
PS1="$PS1"'\w'                 # current working directory
if test -z "$WINELOADERNOEXEC"
then
    PS1="$PS1"'$(__git_ps1)'   # bash function
fi
PS1="$PS1"'\[\033[0m\]'        # change color
PS1="$PS1"'\n'                 # new line
PS1="$PS1"'$ '                 # prompt: always $

# set default options for 'less'
export LESS=-FRSX
export LESSCHARSET=utf-8

# set default protocol for 'plink'
export PLINK_PROTOCOL=ssh

# read user-specific settings, possibly overriding anything above
if [ -e ~/.bashrc ]; then
    . ~/.bashrc
elif [ -e ~/.bash_profile ]; then
    . ~/.bash_profile
elif [ -e /etc/bash_profile ]; then
    . /etc/bash_profile
fi
export LESSCHARSET=utf-8
