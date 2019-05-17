# gvm-v10

This is a customized OpenVAS/Greebone Vulnerability Manager (GVM) v10 Docker container. It is heaily based on the [Atomicorp Docker container](https://github.com/Atomicorp/openvas-docker), but at the time this repo was created, the Atomicorp image was running OpenVAS v9.

The customization of this image mostly boils down to the moving of setup steps into the Dockerfile, to take advantage of Docker's layering for quicker build troubleshooting.

On every build, GVM is installed fresh with the latest NVTs. On every run, the NVTs are updated. To prevent excessively long startup times, the container should be rebuilt regularly.

## Launch

``` shell
docker build -t gvm-v10 .
docker run -d -p 443:443 --name gvm gvm-v10:latest
docker logs --follow gvm

# Once NVTs are loaded, browse to https://localhost/
# Default login / password: admin / admin
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
