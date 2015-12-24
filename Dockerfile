FROM quay.io/letsencrypt/letsencrypt
MAINTAINER kvaps <kvapss@gmail.com>

ADD start.sh /bin/start.sh

ENTRYPOINT [ "/bin/start.sh" ]
