FROM registry.access.redhat.com/ubi8/ubi

MAINTAINER Jan Hutar <jhutar@redhat.com>

WORKDIR /usr/src/app

VOLUME /usr/src/app/hosts_dir

ENV FLASK_APP tdm.py \
    HOSTS_DIR /usr/src/app/hosts_dir

RUN INSTALL_PKGS="python3" \
  && yum -y install $INSTALL_PKGS \
  && yum clean all

COPY requirements.txt .

RUN python3 -m pip install -r /usr/src/app/requirements.txt

COPY . /usr/src/app

USER 1001

CMD ./tdm.sh
