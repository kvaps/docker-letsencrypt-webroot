# docker-letsencrypt
Letsencrypt cert auto renewal for nginx base image

docker-compose.yml
```yaml
letsencrypt:
  restart: always
  image: kvaps/letsencrypt
  hostname: letsencrypt
  volumes:
    - '/etc/localtime:/etc/localtime:ro'
    - '/var/run/docker.sock:/tmp/docker.sock'
    - './letsencrypt/conf:/etc/letsencrypt'
    - './letsencrypt/html:/tmp/letsencrypt'
  environment:
    - 'DOMAINS=example.com www.example.com'
    - 'EMAIL=your@email.tld'
    - 'WEBROOT_PATH=/tmp/letsencrypt'
    - 'EXP_LIMIT=30'
    - 'CHECK_FREQ=30'
```
