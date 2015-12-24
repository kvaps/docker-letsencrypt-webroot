# docker-letsencrypt
Letsencrypt cert auto getting and renewal script based on letsencrypt base image.


Add nginx location for your server:
```nginx
    location '/.well-known/acme-challenge' {
        default_type "text/plain";
        root        /tmp/letsencrypt;
    }
```

docker-compose.yml
```yaml
nginx:
  restart: always
  image: nginx
  hostname: nginx
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - ./nginx:/etc/nginx:ro
    - ./letsencrypt:/etc/letsencrypt
    - ./nginx/letsencrypt:/tmp/letsencrypt
  ports:
    - 80:80
    - 443:443
  environment:
    - LE_RENEW_HOOK=docker kill -s HUP @CONTAINER_NAME@

letsencrypt:
  restart: always
  image: kvaps/letsencrypt
  hostname: letsencrypt
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - /var/run/docker.sock:/tmp/docker.sock
    - ./letsencrypt:/etc/letsencrypt
    - ./nginx/letsencrypt:/tmp/letsencrypt
  links:
    - nginx
  environment:
    - DOMAINS=example.com www.example.com
    - EMAIL=your@email.tld
    - WEBROOT_PATH=/tmp/letsencrypt
    - EXP_LIMIT=30
    - CHECK_FREQ=30
```
