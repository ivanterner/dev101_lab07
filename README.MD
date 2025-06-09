Задание:

Создать образ и запустить контейнер:

- внутри которого будет работать веб-сервер Nginx,

- отдающий статическую html страницу с приветствием с порта,

- для доступа снаружи к nginx по сети пробросить в контейнер порт 54321

- команду запуска контейнера оформить шелл-скриптом

Дополнительное задание:

- Сгенерировать SSL самоподписанный сертификат
    
- Запускать nginx в контейнере с HTTPS протоколом, с сертификатом
    
- Сертификат пробросить в контейнер через Volume Mapping
    
- Сделать скрипт обновления (пересоздания сертификата), который будет давать внутрь докера команду nginx на перечитывание сертификата (reload)

Установка необходимых пакетов
```bash
sudo apt install docker.io 
```
Добавим текущего пользователя в  группу docker
```bash
sudo usermod -aG docker $(whoami)
```

Создаем индексную страницу nginx/index.html
```html
<!DOCTYPE html>
<html>
<head>
<title>DevOps Course 2025</title>
</head>
<body>
DevOps Course 2025!
</body>
</html>
```

Создаем конфиг nginx/nginx-conf/nginx.conf
```bash
server {
        listen 80;

        root /var/www/html;
        index index.html;

        server_name _;

        location / {
                try_files $uri $uri/ =404;
        }
}
```

Создаем Dockerfile nginx/dockerfile
```dockerfile
FROM nginx

ADD ./index.html  /var/www/html/index.html
ADD ./nginx-conf/nginx.conf  /etc/nginx/conf.d/default.conf

RUN /usr/sbin/nginx -t

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
```

Создаем скрипт запуска deoploy.sh
```bash
#!/usr/bin/bash -x


#Стопаем и удаляем старый контейнер, если есть
docker stop nginx-cont
docker rm nginx-cont



#Собираем образ 
docker build -t nginx-server ./nginx

#Создаем и запускаем контейнер
docker run -d --name nginx-cont -p 54321:80 --restart unless-stopped nginx-server

# Проверяем
docker ps -a 
curl 127.0.0.1:54321 
docker logs -n 10 nginx-cont
```

Структура проекта 
```bash
├── deploy.sh
└── nginx
    ├── dockerfile
    ├── index.html
    ├── nginx-conf
    │   └── nginx.conf
    └── README.md
```


Дополнительное задание (HTTPS)

Создаем директорию  и сертификат
```bash
mkdir -p ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/nginx-selfsigned.key \
    -out ssl/nginx-selfsigned.crt \
    -subj "/CN=nginx-server"
```

Обновляем конфиг nginx/nginx-conf/nginx.conf

```bash
server {
        listen 80;
        listen 443 ssl;
        
        ssl_certificate /etc/ssl/nginx-selfsigned.crt;
	ssl_certificate_key /etc/ssl/nginx-selfsigned.key;
	root /var/www/html;
        index index.html;
	
	server_name nginx-server;
	
	location / {
		try_files $uri $uri/ =404;
	}
}
```

Обновляем deoploy.sh

```bash
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

```


 Обновляем Dockerfile nginx/dockerfile (Убираем RUN /usr/sbin/nginx -t)
```dockerfile
FROM nginx

ADD ./index.html  /var/www/html/index.html
ADD ./nginx-conf/nginx.conf  /etc/nginx/conf.d/default.conf

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
```




Сборка и проверка 
```bash
./deploy.sh                                                                                                                                        1 ↵ ──(Mon,Jun09)─┘
Error response from daemon: No such container: nginx-cont
Error response from daemon: No such container: nginx-cont
DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
            Install the buildx component to build images with BuildKit:
            https://docs.docker.com/go/buildx/

Sending build context to Docker daemon   5.12kB
Step 1/5 : FROM nginx
latest: Pulling from library/nginx
61320b01ae5e: Pull complete 
670a101d432b: Pull complete 
405bd2df85b6: Pull complete 
cc80efff8457: Pull complete 
2b9310b2ee4b: Pull complete 
6c4aa022e8e1: Pull complete 
abddc69cb49d: Pull complete 
Digest: sha256:fb39280b7b9eba5727c884a3c7810002e69e8f961cc373b89c92f14961d903a0
Status: Downloaded newer image for nginx:latest
 ---> be69f2940aaf
Step 2/5 : ADD ./index.html  /var/www/html/index.html
 ---> 1b1eb6166b6a
Step 3/5 : ADD ./nginx-conf/nginx.conf  /etc/nginx/conf.d/default.conf
 ---> 7ded91028809
Step 4/5 : STOPSIGNAL SIGTERM
 ---> Running in 3e6ad9b16e96
 ---> Removed intermediate container 3e6ad9b16e96
 ---> 69768696d999
Step 5/5 : CMD ["nginx", "-g", "daemon off;"]
 ---> Running in b446e418674d
 ---> Removed intermediate container b446e418674d
 ---> 6630e1c2a6f5
Successfully built 6630e1c2a6f5
Successfully tagged nginx-server:latest
1691fdbf0fd805be24084831c75a9546307926b61c561d0ea342b0a341f8aa5f
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                                                                                    NAMES
1691fdbf0fd8   nginx-server   "/docker-entrypoint.…"   6 seconds ago   Up 5 seconds   0.0.0.0:54321->80/tcp, [::]:54321->80/tcp, 0.0.0.0:54322->443/tcp, [::]:54322->443/tcp   nginx-cont
<!DOCTYPE html>
<html>
<head>
<title>DevOps Course 2025</title>
</head>
<body>
DevOps Course 2025!
</body>
</html>
<!DOCTYPE html>
<html>
<head>
<title>DevOps Course 2025</title>
</head>
<body>
DevOps Course 2025!
</body>
</html>
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/06/09 17:07:28 [notice] 1#1: using the "epoll" event method
2025/06/09 17:07:28 [notice] 1#1: nginx/1.27.5
2025/06/09 17:07:28 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2025/06/09 17:07:28 [notice] 1#1: OS: Linux 6.8.0-60-generic
2025/06/09 17:07:28 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/06/09 17:07:28 [notice] 1#1: start worker processes
2025/06/09 17:07:28 [notice] 1#1: start worker process 28
172.17.0.1 - - [09/Jun/2025:17:07:38 +0000] "GET / HTTP/1.1" 200 115 "-" "curl/8.5.0" "-"
172.17.0.1 - - [09/Jun/2025:17:07:43 +0000] "GET / HTTP/1.1" 200 115 "-" "curl/8.5.0" "-"
```


Скрипт обновления сертифика
```bash
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

```

Проверяем работу скрипта
```bash
./update-cert.sh                                       
Время выпуска сертификата до обновления
*  start date: Jun  9 17:26:04 2025 GMT
.+.+...+...+...............+.................+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+..+.+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.....+....+............+..+.+.....+....+...........+....+..+.+........+.......+.................+...+...+.+........+...+.........+.........+......+.+..+.........................+......+..............+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.....+.+...+.........+.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+....+......+.........+......+.....+...+..........+..+....+...............+......+...........+............+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*......+...+...+...........................+...+.....+...............+.............+............+........+......+.+..+......+.......+.....+...+..........+...............+......+...........+.......+...+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----
2025/06/09 17:27:36 [notice] 50#50: signal process started
Время выпуска сертификата после обновления
*  start date: Jun  9 17:27:36 2025 GMT
Сертификат обновлен и Nginx перезагружен
```
