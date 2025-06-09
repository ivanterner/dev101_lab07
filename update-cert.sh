#!/bin/bash


echo "Время выпуска сертификата до обновления"
curl -ksv https://127.0.0.1:54322 2>&1 | grep "start date"
# Генерируем новый сертификат
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/nginx-selfsigned.key \
    -out ssl/nginx-selfsigned.crt \
    -subj "/CN=nginx-server"

# Даем команду Nginx на перезагрузку
docker exec nginx-cont nginx -s reload



echo "Время выпуска сертификата после обновления"
curl -ksv https://127.0.0.1:54322 2>&1 | grep "start date"



echo "Сертификат обновлен и Nginx перезагружен"
