#!/usr/bin/bash -x


#Стопаем и удаляем старый контейнер, если есть
docker stop nginx-cont
docker rm nginx-cont



#Собираем образ 
docker build -t nginx-server ./nginx

#Создаем и запускаем контейнер
docker run -d --name nginx-cont -p 54321:80 --restart unless-stopped nginx-server

sleep 15
# Проверяем
docker ps -a 
curl 127.0.0.1:54321 
docker logs -n 10 nginx-cont
