#!/bin/sh
#
# Dumps the database and compresses the output
#

backupdir="$1"
mysqluser=root
options="--single-transaction --extended-insert --disable-keys --quick --set-charset --skip-comments"

if [ -z "$backupdir" ]; then
  backupdir="/var/backups/mysql"
fi

# Optional filter to prevent some databases from being dumped
skip='(tmp|bak|performance_schema|information_schema)$'

exit=0
date

mkdir -p "$backupdir"
umask 027

cd $backupdir
if [ $? -ne 0 ]; then
  echo "Error: cd $backupdir" >&2
  exit 10
fi

for db in `echo 'show databases' | mysql -u $mysqluser | tail -n +2 | egrep -v "$skip"`
do
  echo "Dumping database $db"
  runtime=$(date +%FT%H:%M)
  basename=mysql-$db-$runtime.sql
  mysqldump -u $mysqluser $options $db > $basename

  if [ $? -ne 0 ]; then
    echo "Error dumping $basename" >&2
    exit=21
  else
    # Only reap files (older than a day) if we have a successful dump
    find -type f -name "mysql*.sql.*" -mtime +1 -delete

    nice -n 10 gzip -5 $basename
    if [ $? -ne 0 ]; then
      echo "Error running gzip on $basename" >&2
      exit=25
    fi
  fi
done

date
echo Done

exit $exit
