FROM ubuntu:14.04
LABEL maintainer="Jeff Geerling"

ENV pip_packages "ansible mitogen"

# Install dependencies and upgrade Python.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       software-properties-common \
       python dirmngr curl \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean

# Install Ansible via Pip.
ADD https://bootstrap.pypa.io/get-pip.py .
RUN /usr/bin/python get-pip.py \
  && pip install $pip_packages

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts && \
    echo -e "[defaults]\nstrategy_plugins = $(pip list -v | grep mitogen | awk '{print $3  "/ansible_mitogen/plugins/strategy"}')\nstrategy = mitogen_linear" > /etc/ansible/ansible.cfg

# Workaround for pleaserun tool that Logstash uses
RUN rm -rf /sbin/initctl && ln -s /sbin/initctl.distrib /sbin/initctl

# Create `ansible` user with sudo permissions
ENV ANSIBLE_USER=ansible SUDO_GROUP=sudo
RUN set -xe \
  && groupadd -r ${ANSIBLE_USER} \
  && useradd -m -g ${ANSIBLE_USER} ${ANSIBLE_USER} \
  && usermod -aG ${SUDO_GROUP} ${ANSIBLE_USER} \
  && sed -i "/^%${SUDO_GROUP}/s/ALL\$/NOPASSWD:ALL/g" /etc/sudoers

VOLUME ["/sys/fs/cgroup"]
CMD ["/sbin/init"]
