#!/bin/bash

# examples
#
# backup all the group in config.file
# ./backup.sh -f config.file
#
# specify which group want to backup
# ./backup.sh -f config.file group_name_1 group_name_2
#
# full backup
# ./backup.sh -s source_dir -d dest_dir
#
# incremental backup
# ./backup.sh -i -s source_dir -d dest_dir

timestamp=`date +%Y-%m%d-%H%M%S`

usage()
{
    echo "Usage: "`basename $0`" [-h] [-f config_file | [-n ...] -s source_directory -d destination_directory ]" 1>&2
    exit 2
}

# $1 path
expand_path()
{
    if [[ $1 == *"@"* ]]; then
        echo $1
    else
        echo $(realpath $1)
    fi
}

# $1: source directory
# $2: destination directory
# $3: incremental flag
backup_one_dir()
{
    local src=$(expand_path $1)
    local dest=$(expand_path $2)

    local sync_target="$dest/$(basename $src)-$timestamp"
    local OPTS="-avXA --force --delete"

    if [ $3 -eq 0 ]; then
        rsync $OPTS $src/ $sync_target
    else
        local PRE=`cat lastback`
        OPTS+="--link-dest=$PRE"
        echo "rsync $OPTS $src $sync_target "
        rsync $OPTS $src $sync_target
        echo $sync_target > lastback
    fi
}

# $1: group
# $2: input_dirs
# $3: output_dir
# $4: method
process_group()
{
    echo "processing group $1"
    echo $2 | tr ',' '\n' | while read this_dir; do
        case "$4" in
            f) backup_one_dir $this_dir $3 0;;
            i) backup_one_dir $this_dir $3 1;;
            *) echo "strange method setting in config file";;
        esac
    done
}

main()
{
    [ $# -eq 0 ] && usage
    local tmp_getopts=`getopt -o hif:s:d: -l help,incremental,config-file:,src:,dest: -- "$@"`
    eval set -- "$tmp_getopts"

    echo "parameter $@"
    local file sourcedir
    local has_config_file=0
    local incremental=0
    while true; do
        case "$1" in
            -h|--help)        usage;;
            -f|--config-file) has_config_file=1; file=$2; shift 2;;
            -s|--src)         sourcedir=${2%/}; shift 2;;
            -d|--dest)        destdir=${2%/}; shift 2;;
            -i|--incremental) incremental=1; shift 1;;
            --) shift; break;;
            *) usage;;
        esac
    done

    if [ "$has_config_file" -eq 0 ]; then
        backup_one_dir $sourcedir $destdir $incremental
    else
        if [ $# -eq 0 ]; then
            echo "processing all group specified in $file"
            sed -e 's/#.*//g' -e '/^\s*$/d' "$file" | \
                while read group input_dirs output_dir method; do
                    echo "$group $input_dirs $output_dir $method"
                    process_group $group $input_dirs $output_dir $method
                done
        else
            while [ $# -ne 0 ]; do
                sed -e 's/#.*//g' -e '/^\s*$/d' "$file" | \
                    while read group input_dirs output_dir method; do
                        echo "$group $input_dirs $output_dir $method"
                        if [ "$1" == "$group" ]; then
                            process_group $group $input_dirs $output_dir $method
                        fi
                    done
                shift 1
            done
        fi
    fi
}

main "$@"
