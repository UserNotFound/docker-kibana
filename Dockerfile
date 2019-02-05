FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update && \
    apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby

ENV TAG 6.5
ENV KIBANA_VERSION 6.5.3
ENV KIBANA_DOWNLOAD https://artifacts.elastic.co/downloads/kibana/kibana-oss-6.5.3-linux-x86_64.tar.gz
ENV KIBANA_SHA1SUM 294c90cca9e342d5994ce83e15cbdc9d0d814443


RUN curl -fsSL "${KIBANA_DOWNLOAD}" -o ./installer.tar.gz && \
    echo "${KIBANA_SHA1SUM}  installer.tar.gz" | sha1sum -c - && \
    mkdir /opt/kibana && \
    tar xzf "installer.tar.gz" -C /opt/kibana --strip-components 1 && \
    rm "installer.tar.gz"

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /

RUN rm "/opt/kibana/config/kibana.yml" 
ADD ${TAG}/templates/kibana.yml.erb /opt/kibana/config/



# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin /usr/bin/
RUN chmod 700 /usr/bin/run-kibana.sh
RUN chmod 700 /usr/bin/check-es-version.sh
ADD files/.aptible.yml /.aptible/

# Add tests. Those won't run as part of the build because customers don't need to run
# them when deploying, but they'll be run in test.sh
ADD test /tmp/test
ADD ${TAG}/test /tmp/test

EXPOSE 80

CMD ["/usr/bin/run-kibana.sh"]
