FROM xilinx-vivado:2019.2-full

ENV DEBIAN_FRONTEND=

WORKDIR /

ADD Xilinx.lic /root/.Xilinx/Xilinx.lic
ENV XILINXD_LICENSE_FILE /root/.Xilinx/Xilinx.lic

# Setup ssh
RUN mkdir /root/.ssh/
ADD container /root/.ssh/id_rsa
ADD container.pub /root/.ssh/id_rsa.pub
RUN  echo "    IdentityFile ~/.ssh/id_rsa" >> /etc/ssh/ssh_config
RUN ssh-keyscan gitlab.hpi.de >> ~/.ssh/known_hosts

RUN echo "source /tools/Xilinx/Vivado/2019.2/settings64.sh" >> /root/.snap_profile \
    && echo "export XILINXD_LICENSE_FILE=$XILINXD_LICENSE_FILE" >> /root/.snap_profile \
    && echo "export SNAP_ROOT=$SNAP_ROOT" >> /root/.snap_profile \
    && echo "export LC_ALL=C" >> /root/.snap_profile
ENV BASH_ENV=/root/.snap_profile
RUN echo "source /root/.snap_profile" >> /root/.bashrc

RUN git config --global user.name "Till Lehmann"
RUN git config --global user.email "till.lehmann@student.hpi.de"

# Set the default shell to bash instead of sh
ENV SHELL /bin/bash

CMD tail -f /dev/null
