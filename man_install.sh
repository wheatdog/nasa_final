#! /bin/bash

# execute this script with root access!!!

mandir=`manpath | awk 'BEGIN {FS=":"} {print $1}'`
mkdir -p $mandir/man1
gzip -c backup.sh.1 > "$mandir/man1/backup.sh.1.gz"
gzip -c restore.sh.1 > "$mandir/man1/restore.sh.1.gz"
