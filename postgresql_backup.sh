#!/bin/sh

read -p "Enter your project folder name: " PROJECT
read -p "Enter your project database name: " PROJECT_DB
read -p "Enter postgresql username: " PSQL_USER
read -p "Enter postgresql password: " PSQL_PASSWORD

gem install backup

mkdir -p /var/www/$PROJECT/backup /var/www/$PROJECT/backup/db

cd ~

mkdir Backup

cd Backup

backup generate:model -t $PROJECT_DB --databases=postgresql --compressor=gzip --storages=local

cd models

sudo bash -c "echo -e '
# encoding: utf-8

Model.new(:$PROJECT_DB, \"Dump $PROJECT_DB database\") do

  ##
  # PostgreSQL [Database]
  #
  database PostgreSQL do |db|
    # To dump all databases, set `db.name = :all` (or leave blank)
    db.name               = \"$PROJECT_DB\"
    db.username           = \"$PSQL_USER\"
    db.password           = \"$PSQL_PASSWORD\"
    db.host               = \"localhost\"
    db.port               = 5432
    # db.socket             = "/tmp/pg.sock"
    # When dumping all databases, `skip_tables` and `only_tables` are ignored.
    # db.skip_tables        = ["skip", "these", "tables"]
    # db.only_tables        = ["only", "these", "tables"]
    # db.additional_options = ["-xc", "-E=utf8"]
  end

  ##
  # Local (Copy) [Storage]
  #
  store_with Local do |local|
    local.path       = \"/var/www/$PROJECT/backup/db\"
    local.keep       = 7
  end

  ##
  # Gzip [Compressor]
  #
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
