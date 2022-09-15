FROM ubuntu:18.04
LABEL maintainer=eazytrainning email=eazytrainning@gmail.com
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive  apt-get install -y nginx git
RUN rm -rf  /var/www/html/*
RUN git clone  https://github.com/diranetafen/static-website-example.git  /var/www/html/
EXPOSE 80 
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]