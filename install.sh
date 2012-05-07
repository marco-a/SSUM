#!/bin/bash

#######################
# SSUM install script #
#######################

if [ ! -e "functions.sh" ]; then
	curl -so functions.sh https://raw.github.com/marco-a/SSUM/master/functions.sh
fi

### functions
source "functions.sh"

### prevent exit
prevent_exit

### set environment vars
prompt_start='> '
prompt_end=' : '
SSUM_install_dir="/var/SSUM"
bash_rc_file="/etc/bashrc"

### clear
clear

### check installation
if ( is_dir "$SSUM_install_dir/" && is_file "$SSUM_install_dir/.lock" ) then
	### corrupt installation; clean up
	delete "$SSUM_install_dir/"

	restore "$SSUM_install_dir/.backup" "$bash_rc_file"
fi

if ( ! is_dir "$SSUM_install_dir/" ) then
	mkdir -p "$SSUM_install_dir/"
fi

### backup
backup "$bash_rc_file" "$SSUM_install_dir/.backup"

info "Secured Single User Mode (SSUM) Setup"

### ask for password

password=""
password_repeat=""
while true; do

	if ( is_empty "$password" ) then
		prompt "Please enter a password" 1

		password="$data"

		if ( is_empty "$password" ) then
			error "Password is empty" 0
		fi
	elif ( is_empty "$password_repeat" ) then
		prompt "Please repeat the password" 1

		password_repeat="$data"
	elif [ "$password" != "$password_repeat" ]; then
		password=""
		password_repeat=""

		error "Passwords are not equal" 0
	else
		break
	fi

done

### ask for amount of tries

max_tries=""
while true; do

	if ( is_empty "$max_tries" ) then
		prompt "Please enter the amount of tries [3]"

		max_tries="$data"

		if ( is_empty "$max_tries" ) then
			max_tries=3
		fi
	elif ( ! is_number "$max_tries" ) then
		max_tries=""

		error "This is not a number" 0
	elif [ 0 -ge "$max_tries" ]; then
		max_tries=""

		error "Amount of tries is zero" 0
	else
		break
	fi

done

### ask for action

action=""
while true; do

	if ( is_empty "$action" ) then
		prompt "Decide what happens after $data failed attemps (shutdown|reboot) [shutdown]"

		action="$data"

		if ( is_empty "$action" ) then
			action="shutdown"
		fi
	elif [ "$action" != "shutdown" ] && [ "$action" != "reboot" ]; then
		error "Unknown action \"$action\"" 0

		action=""
	else
		break
	fi

done

### ask for mode

mode=""
while true; do

	if ( is_empty "$mode" ) then
		prompt "Decide which logins you want to protect (SUM|all) [SUM]"

		mode="$data"

		if ( is_empty "$mode" ) then
			mode="SUM"
		fi
	elif [ "$mode" != "SUM" ] && [ "$mode" != "all" ]; then
		error "Unknown mode \"$mode\""

		mode=""
	else
		break
	fi

done

###
SSUM_install "$password" "$max_tries" "$action" "$mode"

exit