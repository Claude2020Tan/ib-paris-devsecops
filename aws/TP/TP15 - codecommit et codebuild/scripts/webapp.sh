#!/bin/bash
#deploy container.
if [ "$DEPLOYMENT_GROUP_NAME" == "webapp-production" ]
then
  sudo docker run --name webapp -d -p 80:80 choco1992/webapp:cicd
fi