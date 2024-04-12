#!/bin/bash

DATE=$(date +%F)
LOGSDIR=/tmp
# /home/centos/shellscript-logs/script-name-date.log
SCRIPT_NAME=$0
LOGFILE=$LOGSDIR/$0-$DATE.log
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
USER="roboshop"
directory="app"

if [ $USERID -ne 0 ];
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ];
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

curl -sL https://rpm.nodesource.com/setup_lts.x | bash &>>$LOGFILE

VALIDATE $? "Setting NPM source"

yum install nodejs -y  &>>$LOGFILE
VALIDATE $? "Installing NodeJS"
#useradd roboshop 
if id -u "$USER" &>/dev/null; 
then
    echo 'user already exists'
else
    sudo useradd "$USER"  &>>$LOGFILE
    VALIDATE $? "User added"
    echo "User $USER added successfully."
fi

if [ ! -d "$directory" ]; 
then
    mkdir "$directory"  &>>$LOGFILE
    echo "Directory created."
else
    echo "Directory already exists."
fi

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip  &>>$LOGFILE
VALIDATE $? "downloading catalogue artifact"

unzip /tmp/catalogue.zip  &>>$LOGFILE
VALIDATE $? "unzipping catalogue"

npm install &>>$LOGFILE
VALIDATE $? "Installing dependencies"

cp /home/centos/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGFILE

VALIDATE $? "copying catalogue.service"

systemctl daemon-reload &>>$LOGFILE

VALIDATE $? "daemon reload"

systemctl enable catalogue &>>$LOGFILE

VALIDATE $? "Enabling Catalogue"

systemctl start catalogue &>>$LOGFILE

VALIDATE $? "Starting Catalogue"

cp /home/centos/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGFILE

VALIDATE $? "Copying mongo repo"

yum install mongodb-org-shell -y &>>$LOGFILE

VALIDATE $? "Installing mongo client"

mongo --host mongodb.weldevops.online </home/centos/roboshop-shell/schema/catalogue.js &>>$LOGFILE

VALIDATE $? "loading catalogue data into mongodb"