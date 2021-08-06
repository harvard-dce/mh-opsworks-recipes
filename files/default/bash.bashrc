# /etc/bashrc

# System wide functions and aliases
# Environment stuff goes in /etc/profile

# It's NOT a good idea to change this file unless you know what you
# are doing. It's much better to create a custom.sh shell script in
# /etc/profile.d/ to make custom changes to your environment, as this
# will prevent the need for merging in future updates.

# are we an interactive shell?
if [ "$PS1" ]; then

  # set a fancy prompt (non-color, unless we know we "want" color)
  case "$TERM" in
  xterm-256color) color_prompt=yes ;;
  screen-256color) color_prompt=yes ;;
  xterm-color) color_prompt=yes ;;
  screen) color_prompt=yes ;;
  esac

  OPSWORKS_CLUSTER=$(ruby -e 'puts $stdin.each.find{|line| line.match(/OpsWorks Stack/)}.split(":").last.strip' </etc/motd)

  case "$OPSWORKS_CLUSTER" in
  *prod*)
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

  # Turn on checkwinsize
  shopt -s checkwinsize
  [ "$PS1" = "\\s-\\v\\\$ " ] && PS1="[\u@\h \W]\\$ "
  # You might want to have e.g. tty in prompt (e.g. more virtual machines)
  # and console windows
  # If you want to do so, just add e.g.
  # if [ "$PS1" ]; then
  #   PS1="[\u@\h:\l \W]\\$ "
  # fi
  # to your custom modification shell script in /etc/profile.d/ directory
fi

if ! shopt -q login_shell; then # We're not a login shell
  # Need to redefine pathmunge, it get's undefined at the end of /etc/profile
  pathmunge() {
    case ":${PATH}:" in
    *:"$1":*) ;;

    *)
      if [ "$2" = "after" ]; then
        PATH=$PATH:$1
      else
        PATH=$1:$PATH
      fi
      ;;
    esac
  }

  # By default, we want umask to get set. This sets it for non-login shell.
  # Current threshold for system reserved uid/gids is 200
  # You could check uidgid reservation validity in
  # /usr/share/doc/setup-*/uidgid file
  if [ $UID -gt 199 ] && [ "$(id -gn)" = "$(id -un)" ]; then
    umask 002
  else
    umask 022
  fi

  # Only display echos from profile.d scripts if we are no login shell
  # and interactive - otherwise just process them to set envvars
  for i in /etc/profile.d/*.sh; do
    if [ -r "$i" ]; then
      if [ "$PS1" ]; then
        . "$i"
      else
        . "$i" >/dev/null 2>&1
      fi
    fi
  done

  unset i
  unset pathmunge
fi
# vim:ts=4:sw=4
