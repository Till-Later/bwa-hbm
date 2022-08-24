# vivado-docker

Vivado installed into a docker image for CI purposes.

## Running

- `docker-compose -f docker-compose.linux.yml build --no-cache`
- `docker-compose -f docker-compose.linux.yml up -d`
- `docker-compose -f docker-compose.linux.yml run dev_vivado /bin/bash`
- `docker-compose -f docker-compose.linux.yml down`
