#!/bin/bash

usage()
{
    echo "Usage: "`basename $0`" [-h] [-f config_file | -s source_directory -d destination_directory ]" 1>&2
    exit 2
}

# $1: from
# $2: to
restore_one_dir()
{
    rm -rf $2
    mkdir -p $(dirname $2)
    scp -r ${1%/} ${2%/}
}

# $1: group
# $2: input_dirs
# $3: output_dir
# $4: time_string
process_group()
{
    echo "processing group $1"
    echo $2 | tr ',' '\n' | while read this_dir; do
        basedir=$(basename $this_dir)
        echo $output_dir
        echo $this_dir
        restore_one_dir ${output_dir%/}/${basedir}-$4 $this_dir
    done
}

main()
{
    [ $# -eq 0 ] && usage
    local tmp_getopts=`getopt -o hf:s:d:t: -l help,config-file:,src:,dest:,time: -- "$@"`
    eval set -- "$tmp_getopts"

    # echo "parameter $@"
    local file sourcedir time
    local has_config_file=0
    while true; do
        case "$1" in
            -h|--help)        usage;;
            -f|--config-file) has_config_file=1; file=$2; shift 2;;
            -s|--src)         sourcedir=${2%/}; shift 2;;
            -d|--dest)        destdir=${2%/}; shift 2;;
            -t|--time)        time=${2%/}; shift 2;;
            --) shift; break;;
            *) usage;;
        esac
    done

    if [ "$has_config_file" -eq 0 ]; then
        restore_one_dir $sourcedir $destdir
    else
        if [ $# -eq 0 ]; then
            echo "processing all group specified in $file"
            sed -e 's/#.*//g' -e '/^\s*$/d' "$file" | \
                while read group input_dirs output_dir method; do
                    echo "$group $input_dirs $output_dir $method"
                    process_group $group $input_dirs $output_dir $time
                done
        else
            while [ $# -ne 0 ]; do
                sed -e 's/#.*//g' -e '/^\s*$/d' "$file" | \
                    while read group input_dirs output_dir method; do
                        echo "$group $input_dirs $output_dir $method"
                        if [ "$1" == "$group" ]; then
                            process_group $group $input_dirs $output_dir $time
                        fi
                    done
                shift 1
            done
        fi
    fi
}

main "$@"
