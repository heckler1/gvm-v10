# gvm-v10

This is a customized OpenVAS/Greebone Vulnerability Manager (GVM) v10 Docker container. It is heaily based on the [Atomicorp Docker container](https://github.com/Atomicorp/openvas-docker), but at the time this repo was created, the Atomicorp image was running OpenVAS v9.

The customization of this image mostly boils down to the moving of setup steps into the Dockerfile, to take advantage of Docker's layering for quicker build troubleshooting.

On every build, GVM is installed fresh with the latest NVTs. On every run, the NVTs are updated. To prevent excessively long startup times, the container should be rebuilt regularly.

## Launch

``` shell
# Build the container
docker build -t gvm-v10 .
# Run a scan
docker run \
  --rm \
  --interactive \
  --tty \
  --volume $(pwd)/gvm_reports:/reports \
  --name gvm \
  gvm-v10:latest \
    --ip 172.17.0.1 \
    --scan-name test \
    --scan-type full-and-fast \
    --report-format pdf
```

## Set admin Password

``` shell
docker run -d -p 443:443 -e GVM_PASSWORD=password --name gvm gvm-v10:latest
```

## Attach to running container

``` shell
docker exec -it gvm bash
```

## Tail the logs

``` shell
docker logs -f gvm
```
