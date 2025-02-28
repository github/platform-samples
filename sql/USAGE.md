# Using the SQL queries

The safest way to run these queries is by using the backup created by [backup-utils](https://github.com/github/backup-utils) loaded into another database server.  This database can be quite large and GitHub Enterprise Server can be sensitive to I/O intensive operations that aren't part of anticipated load.

:warning:  This database contains sensitive information.  Please treat it appropriately within your company / network!

A simple way to do this would be to install a MySQL 5.7 server on the VM receiving the backups and load it automatically.  You can then connect to in using `root` with no password, or whatever you set up for authentication.  What this looks like in practice would be similar to this shell script:

```shell
# Stop MySQL
sudo systemctl stop mysqld.service

# Unzip the most current backup
gunzip -c /data/current/mysql.sql.gz > /data/mysql.tar

# Untar the current backup
tar xf /data/mysql.tar --directory=/home/github/restore-job/

# Remove the temporary tarball
rm /data/mysql.tar

# Clear the data directory before restoring
sudo rm -rf /var/lib/mysql-data/*

# Run the Percona backup restore
cd /home/github/restore-job && sudo innobackupex --defaults-file=backup-my.cnf --copy-back --datadir=/var/lib/mysql-data .

# Restore the innodb buffer pool
sudo cp -n /var/lib/mysql/ib_buffer_pool /var/lib/mysql-data/

# Restore the innodb data
sudo cp -n /var/lib/mysql/ibdata1 /var/lib/mysql-data/

# Restore the first and second logs
sudo cp -n /var/lib/mysql/ib_logfile0 /var/lib/mysql-data/
sudo cp -n /var/lib/mysql/ib_logfile1 /var/lib/mysql-data/

# Reset ownership
sudo chown -R mysql:mysql /var/lib/mysql-data

# Restore SELinux contexts (if applicable)
sudo restorecon -R /var/lib/mysql-data

# Start MySQL
sudo systemctl start mysqld.service

# Clear the working directory to save some disk space
rm -rf /home/github/restore-job/*
```
