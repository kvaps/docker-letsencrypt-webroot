FROM quay.io/letsencrypt/letsencrypt
MAINTAINER kvaps <kvapss@gmail.com>

RUN apt-get update && apt-get -y install docker

ENTRYPOINT [ "letsencrypt" ]
