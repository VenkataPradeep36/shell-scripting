#!/bin/bash

disable-auto-shutdown

HEAD() {
  echo -n -e "\e[1m $1 \e[0m \t\t ..."
}

STAT() {
  if [ $1 -eq 0 ]; then
    echo -e "\e[1;32m done\e[0m"
  else
      echo -e "\e[1;31m Fail\e[0m"
      echo -e "\e[1;33m Check the log for more detail ... Log file : /tmp/roboshop.log\e[0m"
      exit 1
  fi

}

APP_USER_ADD() {
  HEAD "Add RoboShop App USer\t\t"
  id roboshop &>>/tmp/roboshop.log
  if [ $? -eq 0 ]; then
    echo User is already there, so not creating user &>>/tmp/roboshop.log
    STAT $?
  else
    useradd roboshop &>>/tmp/roboshop.log
    STAT $?
  fi
}

SETUP_SYSTEMD() {
  ##Inserting mongodb ip address by using -i command and moving the file
  HEAD "SetUp the SystemD service file"
  sed -i -e 's/MONGO_DNSNAME/mongodb.roboshop.internal/' -e 's/REDIS_ENDPOINT/redis.roboshop.internal/' -e 's/MONGO_ENDPOINT/mongodb.roboshop.internal/' -e 's/CATALOGUE_ENDPOINT/catalogue.roboshop.internal/' -e 's/CARTENDPOINT/cart.roboshop.internal/' -e 's/DBHOST/mysql.roboshop.internal/' -e 's/CARTHOST/cart.roboshop.internal/' -e 's/USERHOST/user.roboshop.internal/' -e 's/AMQPHOST/rabbitmq.roboshop.internal/' /home/roboshop/$1/systemd.service  && mv /home/roboshop/$1/systemd.service /etc/systemd/system/$1.service
  STAT $?

HEAD "Start the $1 service\t"
systemctl daemon-reload && systemctl enable $1 &>>/tmp/roboshop.log && systemctl restart $1 &>>/tmp/roboshop.log

STAT $?
}

DOWNLOAD_FROM_GITGUB() {
  HEAD "Download App From GitHub\t"
  curl -s -L -o /tmp/$1.zip "https://github.com/roboshop-devops-project/$1/archive/main.zip" &>>/tmp/roboshop.log
  STAT $?
  HEAD "Extract the Downloaded Archive"
  cd /home/roboshop && rm -rf $1 && unzip /tmp/$1.zip &>>/tmp/roboshop.log && mv $1-main $1
  STAT $?
}

FIX_APP_CONTENT_PERM() {
    ## We are giving permissions to user by using command chown and -r represents recursively because its a directory and content  inside should change to this one
  HEAD "Fix permissions to Appp User\t"
  chown roboshop:roboshop /home/roboshop -R
  STAT $?

}

NODEJS() {
  HEAD "Install NodeJs\t\t\t"
  yum install nodejs make gcc-c++ -y &>>/tmp/roboshop.log
  STAT $?

  APP_USER_ADD

  DOWNLOAD_FROM_GITGUB $1
  ## In this its unzipping the file and moving catalogue-main to catalogue, but catalogue dir is already there if you run for second time so by avoiding this we have to remove the content before executing

  HEAD "Install NodeJs Dependencies\t"
  ## We need to run this as normal user but to avoiding this we using unsafe perm
  cd /home/roboshop/$1 && npm install --unsafe-perm &>>/tmp/roboshop.log
  STAT $?

  FIX_APP_CONTENT_PERM
  ## need to be Understand
  SETUP_SYSTEMD "$1"

}

MAVEN() {
  HEAD "Install Maven"
  yum install maven -y &>>/tmp/roboshop.log
  STAT $?

  APP_USER_ADD
  DOWNLOAD_FROM_GITGUB $1

  HEAD "Make Application Package"
  cd /home/roboshop/$1/ && mvn clean package &>>/tmp/roboshop.log && mv target/$1-1.0.jar $1.jar >>/tmp/roboshop.log
  STAT $?

  FIX_APP_CONTENT_PERM
  SETUP_SYSTEMD "$1"
}

PYTHON3() {
  HEAD "Install Python3"
  yum install python36 gcc python3-devel -y &>>/tmp/roboshop.log
  STAT $?

  APP_USER_ADD
  DOWNLOAD_FROM_GITGUB $1

  HEAD "Install Python Dependencies"
  cd /home/roboshop/$1 && pip3 install -r requirements.txt &>>/tmp/roboshop.log
  STAT $?
  USER_ID=$(id -u roboshop)
  GROUP_ID=$(id -g roboshop)

  HEAD "Update App Configuration"
  sed -i -e "/uid/ c uid=${USER_ID}" -e "/gid/ c gid=${GROUP_ID}" /home/roboshop/$1/$1.ini
  STAT $?
  ## need to be understand
  SETUP_SYSTEMD $1

}
