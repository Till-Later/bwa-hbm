#! /bin/bash -e

if [ ! -f "$PWD/docktill+xilinx-vivado+2019.2-full.sqsh" ]; then
  enroot import docker://docktill@registry.hub.docker.com#docktill/xilinx-vivado:2019.2-full
fi

enroot create --name xilinx-vivado docktill+xilinx-vivado+2019.2-full.sqsh
chmod -R +x ~/.local/share/enroot/xilinx-vivado

CMD=$(cat <<-END
  cd /root;

  mkdir -p /root/.ssh/;
  cp /deploy/container /root/.ssh/id_rsa;
  cp /deploy/container.pub /root/.ssh/id_rsa.pub;
  eval `ssh-agent -s`
  ssh-add /root/.ssh/id_rsa;
  ssh-keygen -F gitlab.hpi.de || ssh-keyscan gitlab.hpi.de >>~/.ssh/known_hosts;

  echo "source /tools/Xilinx/Vivado/2019.2/settings64.sh" >> /root/.bashrc;
  source /tools/Xilinx/Vivado/2019.2/settings64.sh;
  cp /deploy/Xilinx_licenses/Xilinx_nvram-01.lic /Xilinx.lic;
  echo "export XILINXD_LICENSE_FILE=/Xilinx.lic" >> /root/.bashrc;

  git config --global user.name "Till Lehmann";
  git config --global user.email "till.lehmann@student.hpi.de";
END
)
echo $CMD | enroot start --root --rw --mount $PWD:/deploy xilinx-vivado bash -
