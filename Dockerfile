FROM ubuntu:17.10

MAINTAINER FND <fndemers@gmail.com>

ENV PROJECTNAME=BLOCKCHAIN

ENV WORKDIRECTORY /root

RUN apt-get update

RUN apt install -y git curl python3 python3-pip

# Mise à jour PIP
RUN pip3 install --upgrade pip

ENV PYTHONPATH .

# Installation Flask
#RUN pip install --user flask
RUN pip3 install Flask==0.12.2 requests==2.18.4

RUN cd ${WORKDIRECTORY} \
    && git clone https://github.com/dvf/blockchain

WORKDIR ${WORKDIRECTORY}/blockchain

EXPOSE 5000

CMD python3 blockchain.py -p 5000