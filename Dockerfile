FROM ubuntu:17.10

MAINTAINER FND <fndemers@gmail.com>

ENV PROJECTNAME=BLOCKCHAIN

ENV WORKDIRECTORY /root

RUN apt-get -y update

RUN apt install -y git curl python3 python3-pip
RUN python3 --version
RUN apt-get clean && apt-get -y update && apt-get install -y locales && locale-gen fr_CA.UTF-8
ENV TZ=America/Toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV PYTHONIOENCODING=utf-8

# Mise à jour PIP
RUN pip3 install --upgrade pip

ENV PYTHONPATH .

# Installation Flask
RUN pip3 install Flask==0.12.2 requests==2.18.4

RUN cd ${WORKDIRECTORY} \
    && git clone https://github.com/demers/blockchain

WORKDIR ${WORKDIRECTORY}/blockchain

EXPOSE 5000

CMD python3 blockchain.py --port 5000
