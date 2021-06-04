#!bin/bash

source components/common.sh
## Deleting the previous log content before executing
rm -f /tmp/roboshop.log

HEAD "Install NodeJs"
yum install nodejs make gcc-c++ -y &>>/tmp/roboshop.log
STAT $?

HEAD "Add RoboShop App USer"
id roboshop &>>/tmp/roboshop.log
if [ $? -eq 0 ]; then
  echo User is already there, so not creating user &>>/tmp/roboshop.log
  STAT $?
else
  useradd roboshop &>>/tmp/roboshop.log
  STAT $?
fi


HEAD "Download App From GitHub"
curl -s -L -o /tmp/catalogue.zip "https://github.com/roboshop-devops-project/catalogue/archive/main.zip" &>>/tmp/roboshop.log
STAT $?

HEAD "Extract the Downloaded Archive"
## In this its unzipping the file and moving catalogue-main to catalogue, but catalogue dir is already there if you run for second time so by avoiding this we have to remove the content before executing
cd /home/roboshop && rm -rf && unzip /tmp/catalogue.zip &>>/tmp/roboshop.log && mv catalogue-main catalogue
STAT $?

HEAD " Install NodeJs Dependencies"
## We need to run this as normal user but to avoiding this we using unsafe perm
cd /home/roboshop/catalogue && npm install --unsafe-perm &>>/tmp/roboshop.log
STAT $?




