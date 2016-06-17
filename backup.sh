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
	timestamp=`date +%Y-%m-%d.%H-%M-%S`
	
    if [ $3 -eq 0 ]; then
        sourcebasename=$(basename $1)
	    backupfilename=$2/$sourcebasename.$timestamp.tar.bz2
	    cd ${sourcedir%/*}
	    getfattr -Rd $sourcebasename > $sourcebasename.xattr
	    getfacl -R $sourcebasename > $sourcebasename.acl
		tar -jpc -f $backupfilename $sourcebasename $sourcebasename.acl $sourcebasename.xattr
        rm $sourcebasename.acl $sourcebasename.xattr
	else
        PRE=`cat lastback`
		sync_target="$2/$timestamp"
        OPTS="-avXA --force --delete --link-dest=$PRE"
		rsync $OPTS $1 $sync_target
        echo $sync_target > lastback
	fi
}

main()
{
	[ $# -eq 0 ] && usage
	local tmp_getopts=`getopt -o hf:s:d:i -- "$@"`
	eval set -- "$tmp_getopts"

    #echo "parameter $@"
	local file sourcedir destdir
	local has_config_file=0
	local incremental=0
	while true; do
		case "$1" in
			-h) usage;;
			-f) has_config_file=1; file=$2; shift 2;;
			-s) sourcedir=${2%/}; shift 2;;
			-d) destdir=${2%/}; shift 2;;
			-i) incremental=1; shift 1;;
			--) shift; break;;
			*) usage;;
		esac
	done

    #deal with relative path
    if [ "${sourcedir:0:1}" != "/" ]; then
        sourcedir="`pwd`/$sourcedir"
    fi
    if [ "${destdir:0:1}" != "/" ]; then
        destdir="`pwd`/$destdir"
    fi


	if [ "$has_config_file" -eq 1 ]; then
		echo "Not support config file now!"
	else
		backup_one_dir $sourcedir $destdir $incremental
	fi
}

main "$@"
