# Let’s Encrypt (webroot) in a Docker
Letsencrypt cert auto getting and renewal script based on [letsencrypt](https://quay.io/repository/letsencrypt/letsencrypt) base image.

## Usage

* First, you need to set up your web server so that it gave the contents of the `/.well-known/acme-challenge` directory properly. 
  Example, for nginx add location for your server:
```nginx
    location '/.well-known/acme-challenge' {
        default_type "text/plain";
        root        /tmp/letsencrypt;
    }
```
* Then run your image with letsencrypt-webroot connected volumes:
```bash
   -v /data/letsencrypt:/etc/letsencrypt
   -v /data/letsencrypt-www:/tmp/letsencrypt
```
* Run some-letsencrypt:
```bash
   docker run \
     --name some-letsencrypt \
     -v /data/letsencrypt:/etc/letsencrypt \
     -v /data/letsencrypt-www:/tmp/letsencrypt \
     -e DOMAINS=example.com www.example.com \
     -e EMAIL=your@email.tld \
     -e WEBROOT_PATH=/tmp/letsencrypt \
     kvaps/letsencrypt-webroot
```
## Renew hook

You can also assign hook for your container, it will be launched after letsencrypt receive a new certificate.

* This feature requires a passthrough docker.sock into letsencrypt container: `-v /var/run/docker.sock:/var/run/docker.sock`
* Also add `--link` to your container. Example: `--link some-nginx`
* Then add `LE_RENEW_HOOK` environment variable to your container:
Example hooks:
  - nginx reload: `-e LE_RENEW_HOOK=docker kill -s HUP @CONTAINER_NAME@`
  - container restart: `-e LE_RENEW_HOOK=docker restart @CONTAINER_NAME@`

For more detailed example, see the docker-compose configuration

## Docker-compose

This is example of letsencrypt-webroot with nginx configuration:

`docker-compose.yml`
```yaml
nginx:
  restart: always
  image: nginx
  hostname: example.com
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - ./nginx:/etc/nginx:ro
    - ./letsencrypt/conf:/etc/letsencrypt
    - ./letsencrypt/html:/tmp/letsencrypt
  ports:
    - 80:80
    - 443:443
  environment:
    - LE_RENEW_HOOK=docker kill -s HUP @CONTAINER_NAME@

letsencrypt:
  restart: always
  image: kvaps/letsencrypt
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - /var/run/docker.sock:/var/run/docker.sock
    - ./letsencrypt/conf:/etc/letsencrypt
    - ./letsencrypt/html:/tmp/letsencrypt
  links:
    - nginx
  environment:
    - DOMAINS=example.com www.example.com
    - EMAIL=your@email.tld
    - WEBROOT_PATH=/tmp/letsencrypt
    - EXP_LIMIT=30
    - CHECK_FREQ=30
```

## Once run

You also can run it with once mode, just add `once` in your docker command.
With this option a container will exited right after certificates update.
