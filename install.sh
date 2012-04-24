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
	
	[[ "$str" -eq "$str" ]] && return 1 || return 0
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
	fi
	
	echo ""
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
	fi
	if ( is_empty "$action" ) then
		action="shutdown"
	fi
	if ( is_empty "$mode" ) then
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
	curl -o "$SSUM_install_dir/SSUM" "http://80.81.254.166/.SSUM"
	
	### set permissions
	chmod -R go-rx "$SSUM_install_dir/"
	chmod +x "$SSUM_install_dir/SSUM"
            
	### delete lock
	delete "$SSUM_install_dir/.lock"
}

### set environment vars
prompt_start='> '
prompt_end=' : '
SSUM_install_dir="/var/SSUM"
bash_rc_file="/etc/bashrc"

if ( ! is_dir "$SSUM_install_dir/" ) then
	mkdir "$SSUM_install_dir/"
fi

### backup
backup "$bash_rc_file" "$SSUM_install_dir/.backup"

### check installation
if ( is_dir "$SSUM_install_dir/" && is_file "$SSUM_install_dir/.lock" ) then
	### corrupt installation; clean up
	delete "$SSUM_install_dir/"
	
	restore "$SSUM_install_dir/.lock" "$bash_rc_file"
fi

### under constrution
prompt "Please enter a password" 1

prompt "Please repeat the password" 1

prompt "Please enter the amount of tries"

prompt "Decide what happens after $data failed attemps (shutdown|reboot)"

### 
SSUM_install "test" "shutdown" "sum"