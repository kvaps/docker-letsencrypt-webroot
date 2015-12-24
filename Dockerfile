FROM quay.io/letsencrypt/letsencrypt
MAINTAINER kvaps <kvapss@gmail.com>

RUN echo 'deb http://apt.dockerproject.org/repo ubuntu-trusty main' > /etc/apt/sources.list.d/docker.list \
   && apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
   && apt-get update \
   && apt-get -y install docker-engine

ADD start.sh /bin/start.sh

ENTRYPOINT [ "/bin/start.sh" ]
