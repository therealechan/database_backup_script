#!/bin/sh

read -p "Enter your project folder name: " PROJECT
read -p "Enter your project database name: " PROJECT_DB
read -p "Enter mysql username: " MYSQL_USER
read -p "Enter mysql password: " MYSQL_PASSWORD

gem install backup

sudo mkdir -p /var/www/$PROJECT/backup && chmod 775 $_
sudo mkdir -p /var/www/$PROJECT/backup/db && chmod 775 $_

cd ~

mkdir Backup

cd Backup

backup generate:model -t $PROJECT_DB --databases=mysql --compressor=gzip --storages=local

cd models

sudo bash -c "echo -e '
# encoding: utf-8
Backup::Model.new(:$PROJECT_DB, \"Dumping $PROJECT Database\") do

  database MySQL do |db|
    db.name               = \"$PROJECT_DB\"
    db.username           = \"$MYSQL_USER\"
    db.password           = \"$MYSQL_PASSWORD\"
    db.host               = \"localhost\"
    db.port               = 3306
    db.socket             = \"/var/run/mysqld/mysqld.sock\"
    db.additional_options = [\"--quick\", \"--single-transaction\"]
  end

  store_with Local do |local|
    local.path       = \"/var/www/$PROJECT/backup/db\"
    local.keep       = 7
  end

  compress_with Gzip
end
' > $PROJECT_DB.rb"

backup perform -t $PROJECT_DB

gem install whenever

sudo mkdir -p /var/www/$PROJECT/config && cd $_ && chmod 775 $_

wheneverize .

sudo bash -c "echo -e'
set :output, \"~/Backup/$PROJECT_whenever.log\"
every :day do
  command \"cd ~/Backup && backup perform -t $PROJECT_DB\"
end
' > config/schedule.rb"

whenever --update-crontab
