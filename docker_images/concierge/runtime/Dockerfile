FROM ubuntu:focal

RUN echo '## Adding canocial repos from Dockerfile' >> /etc/apt/source.list
RUN echo 'deb http://archive.canonical.com/ubuntu focal partner' >> /etc/apt/sources.list
RUN echo 'deb-src http://archive.canonical.com/ubuntu focal partner' >> /etc/apt/sources.list

RUN apt-get update && apt-get upgrade -y 
RUN apt-get install -y openjdk-21-jre
RUN apt-get install -y wget
RUN apt-get install -y iputils-ping

COPY dumb-init /usr/local/bin/dumb-init 
RUN chmod +x /usr/local/bin/dumb-init

WORKDIR /app

RUN useradd -rm -d /home/concierge -s /bin/bash -g root -G users -u 1001 concierge && chown -R concierge:root /app

USER concierge

ENTRYPOINT ["/bin/echo"]

CMD ["Plase override ENTRYPOINT and CMD arguments as you require. Finishing container execution."]

