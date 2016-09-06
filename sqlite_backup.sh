#!/bin/sh

read -p "Enter your project folder name: " PROJECT
read -p "Enter your project database name: " PROJECT_DB
read -p "Enter your database path: " DB_PATH

gem install backup

mkdir -p /var/www/$PROJECT/backup /var/www/$PROJECT/backup/db

cd ~

mkdir Backup

cd Backup

backup generate:model -t $PROJECT_DB --databases=sqlite --compressor=gzip --storages=local

cd models

sudo bash -c "echo -e '
# encoding: utf-8

Model.new(:my_backup, 'My Backup') do
  database SQLite do |db|
    # Path to database
    db.path               = \"$DB_PATH\"
    # Optional: Use to set the location of this utility
    #   if it cannot be found by name in your PATH
    db.sqlitedump_utility = \"/opt/local/bin/sqlite3\"
  end
end

  ##
  # Local (Copy) [Storage]
  #
  store_with Local do |local|
    local.path       = \"/var/www/$PROJECT/backup/db\"
    local.keep       = 7
  end

  compress_with Gzip

end
' > $PROJECT_DB.rb"

backup perform -t $PROJECT_DB

# Use whenever to automatic backup database
gem install whenever

cd /var/www/$PROJECT

mkdir config

wheneverize .

sudo bash -c "echo -e '
set :output, \"~/Backup/${PROJECT}"_whenever.log"\"
# Here to set up auto backup database once a day
# More info please see https://github.com/javan/whenever#example-schedulerb-file
every :day do
  command \"cd ~/Backup && backup perform -t $PROJECT_DB\"
end
' > config/schedule.rb"

whenever --update-crontab
