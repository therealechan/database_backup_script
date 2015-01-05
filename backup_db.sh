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

##
# Backup Generated: $PROJECT_DB
# Once configured, you can run the backup with the following command:
#
# $ backup perform -t $PROJECT_DB [-c <path_to_configuration_file>]
#
# For more information about Backup's components, see the documentation at:
# http://meskyanichi.github.io/backup
#
Model.new(:$PROJECT_DB, \'Dump $PROJECT_DB database\') do

  ##
  # MySQL [Database]
  #
  database MySQL do |db|
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = \"$PROJECT_DB\"
    db.username           = \"$MYSQL_USER\"
    db.password           = \"$MYSQL_PASSWORD\"
    db.host               = \"localhost\"
    db.port               = 3306
    db.socket             = \"/var/run/mysqld/mysqld.sock\"
    db.additional_options = [\"--quick\", \"--single-transaction\"]
  end

  ##
  # Local (Copy) [Storage]
  #
  store_with Local do |local|
    local.path       = \"/var/www/$PROJECT/backup/db\"
    local.keep       = 7
  end

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
