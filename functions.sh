# prevents exit
prevent_exit() {
	trap "" 20
	trap "" TSTP
	trap "" INT TERM
	trap "" INT
}

# checks internet connection
check_inet() {
	if eval "ping -c 1 4.2.2.1 > /dev/null 2>&1"; then
		return 0
	else
		return 1
	fi
}

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
	local password="$1"
	local amount_of_tries="$2"
	local action="$3"
	local mode="$4"

	### make lock
	write "$SSUM_install_dir/.lock"

	### validate vars
	if ( is_empty "$password" ) then
		password=1234
	elif ( is_empty "$amount_of_tries" || ! is_number "$amount_of_tries" ) then
		amount_of_tries=3
	elif ( is_empty "$action" ) then
		action="shutdown"
	elif ( is_empty "$mode" ) then
		mode="sum"
	fi

	### write config
	write "$SSUM_install_dir/.config" "# SSUM config file"
	write "$SSUM_install_dir/.config" "amount_of_tries=\"$amount_of_tries\"" 1
	write "$SSUM_install_dir/.config" "action=\"$action\"" 1
	write "$SSUM_install_dir/.config" "mode=\"$mode\"" 1
	write "$SSUM_install_dir/.config" "password=\"$password\"" 1
	write "$SSUM_install_dir/.config" "# end SSUM config file" 1

	### patch bashrc file
	write "$bash_rc_file" "if [ \"\$EUID\" == \"0\" ]; then" 1
	write "$bash_rc_file" "    $SSUM_install_dir/SSUM" 1
	write "$bash_rc_file" "fi" 1

	### create SSUM file
	write "$SSUM_install_dir/SSUM"

	### download latest release
	curl -so "$SSUM_install_dir/SSUM" "https://raw.github.com/marco-a/SSUM/master/SSUM"

	### set permissions
	chmod -R go-rx "$SSUM_install_dir/"
	chmod +x "$SSUM_install_dir/SSUM"

	mv functions.sh "$SSUM_install_dir/functions.sh"
            
	### delete lock
	delete "$SSUM_install_dir/.lock"

	success "SSUM successfully installed"
}