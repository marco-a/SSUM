#!/bin/bash

#######################
# SSUM install script #
#######################

### functions
is_dir() {
	local dir="$1"
	
	[[ -d "$dir" ]] && return 0 || return 1
}

is_file() {
	local file="$1"
	
	[[ -e "$file" ]] && return 0 || return 1
}

delete() {
	local dest="$1"
	
	rm -rf "$dest"
}

### set environment vars
SSUM_install_dir="/var/SSUM/"

### check installation
if ( is_dir "$SSUM_install_dir" && is_file "$SSUM_install_dir.lock" ) then
	### corrupt installation; clean up
	delete "$SSUM_install_dir"
fi