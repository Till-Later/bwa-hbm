# Run vivado build inside enroot environment
## Install
- Insert the following files into this directoy:
  - a Xilinx License, name it `Xilinx.lic`
  - ssh keys for git access to this repository, name them `container[.pub]`
- You might adjust the login data for Docker Hub (currently `docktill`), your git credentials and the git host address (currently `gitlab.hpi.de`).
- Run `./deploy.sh`

## Run
- Configure your builds inside `scripts/image_builder/run.py` (copy the `scripts/image_builder` directory into this directory)
- Open shell inside enroot container, using `./interactive.sh`
- Start build runner using `python3 /deploy/run.py` inside the container.
