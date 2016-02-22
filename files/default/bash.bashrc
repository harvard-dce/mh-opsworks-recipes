# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    # Fixed by DJCP, was "xterm-color", not the correct value.
    xterm-256color) color_prompt=yes;;
    screen-256color) color_prompt=yes;;
    xterm-color) color_prompt=yes;;
esac

# set a fancy prompt (non-color, overwrite the one in /etc/profile)
# PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

# Set opsworks cluster name in prompt - DJCP
OPSWORKS_CLUSTER=`ruby -e 'puts $stdin.each.find{|line| line.match(/OpsWorks Stack/)}.split(":").last.strip' < /etc/motd`

case "$OPSWORKS_CLUSTER" in
*production*)
  # Red background with white text. CAUTION WHOOP WHOOP!
  cluster_color="41"
  ;;
*)
  # A calm pleasing yellow.
  cluster_color="33"
  ;;
esac

if [ "$color_prompt" = yes ]; then
  PROMPT_COMMAND='echo -n -e "\033[01;${cluster_color}m${OPSWORKS_CLUSTER}\033[00m - "'
else
  PROMPT_COMMAND='echo -n -e "${OPSWORKS_CLUSTER} - "'
fi

# /Set opsworks cluster name in prompt - DJCP

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

# enable bash completion in interactive shells
#if ! shopt -oq posix; then
#  if [ -f /usr/share/bash-completion/bash_completion ]; then
#    . /usr/share/bash-completion/bash_completion
#  elif [ -f /etc/bash_completion ]; then
#    . /etc/bash_completion
#  fi
#fi

# sudo hint
if [ ! -e "$HOME/.sudo_as_admin_successful" ] && [ ! -e "$HOME/.hushlogin" ] ; then
    case " $(groups) " in *\ admin\ *)
    if [ -x /usr/bin/sudo ]; then
	cat <<-EOF
	To run a command as administrator (user "root"), use "sudo <command>".
	See "man sudo_root" for details.
	
	EOF
    fi
    esac
fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
	function command_not_found_handle {
	        # check because c-n-f could've been removed in the meantime
                if [ -x /usr/lib/command-not-found ]; then
		   /usr/lib/command-not-found -- "$1"
                   return $?
                elif [ -x /usr/share/command-not-found/command-not-found ]; then
		   /usr/share/command-not-found/command-not-found -- "$1"
                   return $?
		else
		   printf "%s: command not found\n" "$1" >&2
		   return 127
		fi
	}
fi
