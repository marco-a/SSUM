#!/bin/bash

#######################
# SSUM install script #
#######################

### functions

# checks if a directory exist
is_dir() {
	local dir="$1"
	
	[[ -d "$dir" ]] && return 0 || return 1
}

# checks if a file exist
is_file() {
	local file="$1"
	
	[[ -e "$file" ]] && return 0 || return 1
}

# checks if a string is empty
is_empty() {
	local str="$1"
	
	[[ -z "$str" ]] && return 0 || return 1
}

# checks if a string is a number
is_number() {
	local str="$1"
	
	[[ "$str" =~ ^[0-9]+$ ]] && return 0 || return 1
}

# deletes a file / directory
delete() {
	local dest="$1"
	
	rm -rf "$dest"
}

# backups a file
backup() {
	local source="$1"
	local backup="$2"
	
	if ( is_file "$backup" || ! is_file "$source" ) then
		return 1
	fi
	
	cp "$source" "$backup"
}

# restores a file from a backup
restore() {
	local backup="$1"
	local dest="$2"
	
	if ( ! is_file "$backup" ) then
		return 1
	fi
	
	cp "$backup" "$dest"
}

# writes to a file
write() {
	local file="$1"
	local content="$2"
	local append="$3"
	
	if ( ! is_file "$file" ) then
		touch "$file"
	fi
	
	if ( is_empty "$append" ) then
		echo "$content" > "$file"
	else
		echo "$content" >> "$file"
	fi
}

# info output
info() {
	local str="$1"
	
	echo -e "\033[0;36m$prompt_start$str\033[0m"
}

# error output
error() {
	local str="$1"
	local exit="$2"
	
	echo -e "\033[0;31m$prompt_start$str\033[0m"
	
	if ( is_empty "$exit" ) then
		exit
	fi
}

# success output
success() {
	local str="$1"
	
	echo -e "\033[0;32m$prompt_start$str\033[0m"
}

# show prompt
prompt() {
	local dialog="$1"
    local hide="$2"
	
	echo -n "$prompt_start$dialog$prompt_end"
    
    if ( ! is_empty "$hide" ) then
		stty -echo
	fi
	
	read data;
	
	if ( ! is_empty "$hide" ) then
		stty echo
	
		echo ""
	fi
}

# installs SSUM
SSUM_install() {
	local amount_of_tries="$1"
	local action="$2"
	local mode="$3"
	
	### make lock
	write "$SSUM_install_dir/.lock"
	
	### validate vars
	if ( is_empty "$amount_of_tries" || ! is_number "$amount_of_tries" ) then
		amount_of_tries=3
	elif ( is_empty "$action" ) then
		action="shutdown"
	elif ( is_empty "$mode" ) then
		mode="sum"
	fi
	
	### write config
	write "$SSUM_install_dir/.config" "amount_of_tries = $amount_of_tries"
	write "$SSUM_install_dir/.config" "action = $action" 1
	write "$SSUM_install_dir/.config" "mode = $mode" 1
	
	### patch bashrc file
	write "$bash_rc_file" "if ( \"\$EUID\" == \"0\" ) then" 1
	write "$bash_rc_file" "    $SSUM_install_dir/SSUM" 1
	write "$bash_rc_file" "fi" 1
	
	### create SSUM file
	write "$SSUM_install_dir/SSUM"
	
	### download latest release
	curl -so "$SSUM_install_dir/SSUM" "http://80.81.254.166/.SSUM"
	
	### set permissions
	chmod -R go-rx "$SSUM_install_dir/"
	chmod +x "$SSUM_install_dir/SSUM"
            
	### delete lock
	delete "$SSUM_install_dir/.lock"
	
	success "SSUM successfully installed"
}

### set environment vars
prompt_start='> '
prompt_end=' : '
SSUM_install_dir="/var/SSUM"
bash_rc_file="/etc/bashrc"

### clear
clear

### backup
backup "$bash_rc_file" "$SSUM_install_dir/.backup"

### check installation
if ( is_dir "$SSUM_install_dir/" && is_file "$SSUM_install_dir/.lock" ) then
	### corrupt installation; clean up
	delete "$SSUM_install_dir/"
	
	restore "$SSUM_install_dir/.lock" "$bash_rc_file"
fi

if ( ! is_dir "$SSUM_install_dir/" ) then
	mkdir -p "$SSUM_install_dir/"
fi

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
		prompt "Please enter the amount of tries"
		
		max_tries="$data"
	
		if ( is_empty "$max_tries" ) then
			error "Amount of tries is empty" 0
		fi
	elif ( ! is_number "$max_tries" ) then
		max_tries=""
		
		error "This is not a number" 0
	elif [ "0" -ge "$max_tries" ]; then
		max_tries=""
		
		error "Amount of tries is zero" 0
	else
		break
	fi
	
done

prompt "Decide what happens after $data failed attemps (shutdown|reboot)"

action="$data"

if [ "$action" != "shutdown" ] && [ "$action" != "reboot" ]; then
	info "Use shutdown as action"
	
	action="shutdown"
fi

prompt "Decide which logins you want to protect (SUM|all)"

mode="$data"

if [ "$mode" != "SSUM" ] && [ "$mode" != "all" ]; then
	info "Use SUM as action"
	
	mode="SUM"
fi

### 
SSUM_install "$max_tries" "$action" "$mode"