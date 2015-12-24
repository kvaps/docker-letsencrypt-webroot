FROM quay.io/letsencrypt/letsencrypt
MAINTAINER kvaps <kvapss@gmail.com>

RUN apt-get update && apt-get -y install docker.io

ADD start.sh /bin/start.sh

ENTRYPOINT [ "/bin/start.sh" ]
