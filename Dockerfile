FROM quay.io/letsencrypt/letsencrypt
MAINTAINER kvaps <kvapss@gmail.com>

RUN apt-get update
RUN apt-get -y install docker.io
RUN apt-get clean
RUN rm -r /var/lib/apt/lists/*

ADD start.sh /bin/start.sh

ENTRYPOINT [ "/bin/start.sh" ]
