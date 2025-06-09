#!/usr/bin/bash -x


#Стопаем и удаляем старый контейнер, если есть
docker stop nginx-cont
docker rm nginx-cont



#Собираем образ 
docker build -t nginx-server ./nginx

#Создаем и запускаем контейнер
docker run -d --name nginx-cont -p 54321:80 -p 54322:443 -v $(pwd)/ssl:/etc/ssl:ro  --restart unless-stopped nginx-server

sleep 5
# Проверяем

docker ps -a 
sleep 5
curl 127.0.0.1:54321 
sleep 5
curl -k https://127.0.0.1:54322
docker logs -n 10 nginx-cont
