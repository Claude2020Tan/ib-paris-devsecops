FROM nginx
LABEL maintainer='ULRICH MONJI'
RUN apt-get update
ADD static-website-example/ /usr/share/nginx/html/
EXPOSE 80
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]