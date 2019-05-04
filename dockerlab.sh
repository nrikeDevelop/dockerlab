#!/bin/bash

##print with color
NC='\033[0m' # No Color
function echo_e(){
	case $1 in 
		red)	echo -e "\033[0;31m$2 ${NC} " ;;
		green) 	echo -e "\033[0;32m$2 ${NC} " ;;
		yellow) echo -e "\033[0;33m$2 ${NC} " ;;
		blue)	echo -e "\033[0;34m$2 ${NC} " ;;
		purple)	echo -e "\033[0;35m$2 ${NC} " ;;
		cyan) 	echo -e "\033[0;36m$2 ${NC} " ;;
		*) echo $1;;
	esac
}

function banner(){
echo '
 _____             _             _           _     
|  __ \           | |           | |         | |    
| |  | | ___   ___| | _____ _ __| |     __ _| |__  
| |  | |/ _ \ / __| |/ / _ \ `__| |    / _` | `_ \ 
| |__| | (_) | (__|   <  __/ |  | |___| (_| | |_) |
|_____/ \___/ \___|_|\_\___|_|  |______\__,_|_.__/ 

'
}

function die(){
    exit 0
}

function renameProject(){
  mv $(ls | grep _container) $1_container
}

function start(){
    cd $(ls | grep _container)
    docker-compose up -d 
    die
}

function stop(){
    cd $(ls | grep _container)
    docker-compose down 
    die
}

#$1 Default value
function normalize_config(){ 
    read VALUE
    if [ -z $VALUE ];then 
        VALUE=$1
    fi
    echo $VALUE
}

#ADD PORTS, AND NEW CONFIGURATIONS TO /BIN/.. AND DOCKER-COMPOSE.YML
function config(){
    echo_e yellow "[+] Configure parameters"
    echo ""
    echo -ne "Name of project       (default: docker_container) : "; NAME_PROJECT=$(normalize_config "docker"); renameProject $NAME_PROJECT 
    echo -ne "Redirect port Apache  (default: 80) : "   ; PORT_APACHE=$(normalize_config "80")
    echo -ne "Redirect port Mysql   (default: 3306) : " ; PORT_MYSQL=$(normalize_config "3306")
    echo -ne "User Mysql            (default: admin) : "; USER_MYSQL=$(normalize_config "admin")
    echo -ne "Password Mysql        (default: 1234) : " ; PASSWORD_MYSQL=$(normalize_config "1234")
    echo -ne "Root Password Mysql   (default: 1234) : " ; PASSWORD_ROOT_MYSQL=$(normalize_config "1234")
    echo -ne "Redirect port Node    (default: 3000) : " ; PORT_NODE=$(normalize_config "3000")
    echo ""
    echo_e yellow "[+] Configuring docker-compose.yml"


rm ${PWD}/$NAME_PROJECT"_container"/docker-compose.yml
echo '
version: "2.0"
services:
  web:
    build: ${PWD}/bin/webserver
    volumes:
      - ${PWD}/www/:/var/www/html/
    ports:
      - "'$PORT_APACHE':80"
  db:
    image: mariadb
    restart: always
    environment:
      MYSQL_USER: '$USER_MYSQL'
      MYSQL_PASSWORD: '$PASSWORD_MYSQL'
      MYSQL_ROOT_PASSWORD: '$PASSWORD_ROOT_MYSQL'
    ports:
     - "'$PORT_MYSQL':3306"
    stdin_open: true
    volumes:
     - ${PWD}/mysql/:/var/lib/mysql    
    networks:
     - backend 
  node:
    image: node
    volumes:
     - ${PWD}/root:/root
    ports:
     - "'$PORT_NODE':3000"
    command: bash -c "cd /root/ && npm install && npm install nodemon -g && nodemon app.js"
networks:
  backend:
' >> ${PWD}/$NAME_PROJECT"_container"/docker-compose.yml


  if [ -f ${PWD}/$NAME_PROJECT"_container"/www/index.html ]
  then
    rm ${PWD}/$NAME_PROJECT"_container"/www/index.html
  fi

echo '
<html>
<head>
<link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
<link rel="stylesheet" href="https://code.getmdl.io/1.3.0/material.indigo-pink.min.css">
<script defer src="https://code.getmdl.io/1.3.0/material.min.js"></script>
</head>
<body>
<div style="margin:50px;">
<h2>'$NAME_PROJECT'</h2>
<p>
Copy the web content in /www, the database in /mysql (no db.sql)<br>
and the node server in /root folder, this will be executed automatically <br>
with each reboot.
<p>
<p>
<h4>MYSQL</h4>
root pass:'$PASSWORD_ROOT_MYSQL'<br>
user :    '$USER_MYSQL'<br>
pass :    '$PASSWORD_MYSQL'<br>
</p>
</div>
</body>
</html>
' >> ${PWD}/$NAME_PROJECT"_container"/www/index.html

  ${PWD}/dockerlab.sh --start

  echo ""
  echo ""
  echo_e green "[+] Configurated"
  echo_e yellow "[?] To start ./dockerlab.sh --start"
  echo ""
  echo_e yellow "Copy web files in ./docker_container/www"
  echo_e yellow "Access it http://localhost:"$PORT_APACHE

}

#MAIN

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

banner
case $1 in
    "--start")      
          start
          die ;;
    "--stop")      
          stop
          die ;;
    "--config")      
        config
        die ;;
     *)
          echo "DockerLab"
          echo "This script make a workspace to schedule in apache-php/node and mysql"
          echo "dockerlab ( --start | --stop | --config )"
          ;;
esac