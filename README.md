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
letsencrypt:
  restart: always
  image: kvaps/letsencrypt
  hostname: letsencrypt
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - /var/run/docker.sock:/tmp/docker.sock
    - ./letsencrypt/conf:/etc/letsencrypt
    - ./letsencrypt/html:/tmp/letsencrypt
  environment:
    - DOMAINS=example.com www.example.com
    - EMAIL=your@email.tld
    - WEBROOT_PATH=/tmp/letsencrypt
    - EXP_LIMIT=30
    - CHECK_FREQ=30
```
