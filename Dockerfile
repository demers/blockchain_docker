FROM ubuntu:17.10

MAINTAINER FND <fndemers@gmail.com>

ENV WORKDIRECTORY /root

RUN apt-get update

RUN apt install -y python-pip git \
    && pip install --upgrade pip

#RUN pip install --user flask
RUN pip install Flask==0.12.2 requests==2.18.4

WORKDIR ${WORKDIRECTORY}/blockchain

git clone https://github.com/dvf/blockchain

EXPOSE 5000

CMD python blockchain.py