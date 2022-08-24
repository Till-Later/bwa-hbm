#! /bin/bash -e

INSTALLER_DIR=$PWD/installer

if [ ! -d "$INSTALLER_DIR" ]; then
  mkdir $INSTALLER_DIR
  cp install_config.txt $INSTALLER_DIR/install_config.txt
fi

docker build -t xilinx-base -f Dockerfile $INSTALLER_DIR

if [ ! -d "$INSTALLER_DIR/Xilinx_Vivado" ]; then
  mkdir $INSTALLER_DIR/Xilinx_Vivado && tar -xvzf Xilinx_Vivado_2019.2_1106_2127.tar.gz -C $INSTALLER_DIR/Xilinx_Vivado --strip-components 1
fi

docker run --name xilinx-install -v $INSTALLER_DIR:/installer xilinx-base /installer/Xilinx_Vivado/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config /install_config.txt
docker commit xilinx-install xilinx-vivado:2019.2-full
docker login
docker tag xilinx-vivado:2019.2-full docktill/xilinx-vivado:2019.2-full
docker push docktill/xilinx-vivado:2019.2-full
docker rm xilinx-install

echo "Remember to make the image private at Docker Hub!"
