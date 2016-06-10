#!/bin/bash

usage()
{
	echo "Usage: "`basename $0`" [-h] [-f config_file | -s source_directory -d destination_directory]" 1>&2
	exit 2
}

# $1: source directory
# $2: destination directory
backup_one_dir()
{
	sourcebasename=$(basename $1)
	backupfilename=$2/$sourcebasename.$(date +%Y-%m-%d.%H-%M-%S).tar.bz2
	cd ${sourcedir%/*}
	getfattr -Rd $sourcebasename > $sourcebasename.xattr
	getfacl -R $sourcebasename > $sourcebasename.acl
	tar -jpc -f $backupfilename $sourcebasename $sourcebasename.acl $sourcebasename.xattr
	rm $sourcebasename.acl $sourcebasename.xattr
}

main()
{
	[ $# -eq 0 ] && usage
	local tmp_getopts=`getopt -o hf:s:d: -- "$@"`
	eval set -- "$tmp_getopts"

	local file sourcedir destdir
	local has_config_file=0
	while true; do
		case "$1" in
			-h) usage;;
			-f) has_config_file=1; file=$2; shift 2;;
			-s) sourcedir=${2%/}; shift 2;;
			-d) destdir=${2%/}; shift 2;;
			--) shift; break;;
			*) usage;;
		esac
	done

	if [ "$has_config_file" -eq 1 ]; then
		echo "Not support config file now!"
	else
		backup_one_dir $sourcedir $destdir
	fi
}

main "$@"
