FROM quay.io/letsencrypt/letsencrypt
MAINTAINER Anton Ohorodnyk <anton@ohorodnyk.name>

RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates && \
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
    echo "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -sc) main" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get -y install docker-engine && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD start.sh /bin/start.sh

ENTRYPOINT [ "/bin/start.sh" ]
