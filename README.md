# CiviCRM Modular installer/upgrader

## Features:
Downloads and installs CiviCRM with Drupal 7 and drush on a clean server
Uses Docker to manage services (mysql, mail server, backups)
Takes daily backups and stores them on dropbox.
Can create an empty site or restore an existing one from dropbox
Upgrading is as simple as changing the desired versions in the .env file and rebuilding

## Modules
* Drupal 7 on php-fpm
* mariadb -capable of drop-in replacement with mysql or percona
* mail server- change smtp options with .env file
* Nginx webserver
* Traefik reverse proxy
* Duplicity for backing up DB's and user uploads
* Drush for management needs

# How to use

## Server Setup
* Tested on Ubuntu 18.04 and 19.04 -it should function with only minimal modification on any docker host
### Install docker
```bash
# Add the docker repository
sudo apt-get install apt-transport-http
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# For lts ubuntu, run
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Non-lts (i.e, 19.04) may require the edge and tesing repositories
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable edge test"

sudo apt update
sudo apt install docker-ce
sudo systemctl enable docker   
```
### Install docker-compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" \
     -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
### Set up an empty git repository to receive code via git push
```bash
mkdir CRM.git
cd CRM.git
git init --shared 
git config receive.denyCurrentBranch updateinstead
```
### install the pwgen utility to generate random passwords
```bash
sudo apt install pwgen
```
#### create a local docker registry to hold the custom php and drush images- this could also be on a different server or public host
```bash
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

### Once the git repository is populated, there may need to be some permission changes
```bash
# acme.json requires 600 permissions
sudo chmod 600 traefik/acme.json
```

### Create and mount a swapfile
The versions of ubuntu I've tested seem to have a bug when memory usage gets high, the kswapd0 utility will lock the cpu at 100% seemingly waiting for non-existent swap to kick in. To mitigate this, I create a 4GB swapfile
```bash
sudo dd if=/dev/zero of=/swapfile bs=4M count=1024
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo nano /etc/fstab

# add this line to fstab to mount swap at boot
 /swapfile swap swap defaults 0 0
```
### May need to set the timezone on the server so scheduled jobs run when expected
```bash
sudo dpkg-reconfigure tzdata
```

## Local git setup
Assuming you already have the code in a working local git repository-
Add the server as a remote named live (or whatever)
```bash
git remote add live ssh://crm.example.com/home/ubuntu/CRM.git
git push live +master:refs/heads/master

# use git push to send any committed changes to the server
git push live master
```
I'm using the master branch on the live server, but you could use any branch, just push it to the server and then from the server checkout the desired branch.

# Upgrading a running system
ssh into working crm
change CRM git directory
commit any changes? -should only be ssl updates
on dev/staging, pull the changes to acme.json and then push the new config files with updated versions

on crm, run a full backup
```bash
sudo ./cron-backup.sh
```

then run the restore script
```bash
sudo ./clean-restore.sh
```
## NB:
You may want to pull the site key when you run the update.
sudo docker-compose -f docker-compose.yml -f docker-compose-scheduled.yml run --entrypoint /bin/sh drupal-backup

key is in sites/default/civicrm.settings.php

# Start serving
```bash
sudo docker-compose up -d
```
# Launch drush for customization
```bash
sudo docker-compose -f docker-compose.yml -f docker-compose-scheduled.yml run --entrypoint /bin/sh drupal-backup
```


