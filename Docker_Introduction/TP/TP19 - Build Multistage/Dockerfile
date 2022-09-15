FROM ubuntu:18.04 as files
LABEL Name="Frazer SADO"
LABEL email="sadofrazer@yahoo.fr"
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git
RUN mkdir /opt/files
RUN git clone https://github.com/daviddias/static-webpage-example.git /opt/files/

FROM httpd as httpd
LABEL Name="Frazer SADO"
LABEL email="sadofrazer@yahoo.fr"
EXPOSE 80
COPY --from=files /opt/files/src/ /usr/local/apache2/htdocs/

FROM nginx as nginx
LABEL Name="Frazer SADO"
LABEL email="sadofrazer@yahoo.fr"
EXPOSE 80
COPY --from=files /opt/files/src/ /usr/share/nginx/html/