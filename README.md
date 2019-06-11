# gvm-v10

This is a customized OpenVAS/Greebone Vulnerability Manager (GVM) v10 Docker container. It is based on the [Atomicorp Docker container](https://github.com/Atomicorp/openvas-docker), but at the time this repo was created, the Atomicorp image was running OpenVAS v9. However, this image is structured quite differently from the Atomicorp image.

The notable differences in this image stem primarily from the fact that the image does not run a GVM server anymore. Instead, on invocation, the image runs a vulnerability scan using the provided options, and then dies. This allows for ephemeral scanning, where the entire scan process is contained within the Docker container.

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

## Server configuration

The base of the gvm-v10 ephemeral scanning container can also be used for a long-running server, by building `Dockerfile.server`. The two containers share the majority of their layers, so ideally they should be built together to save time and disk space.

``` shell
# Build the container
docker build -f Dockerfile.server -t gvm-server-v10 .
# Run the server
docker run \
  --rm \
  --detach \
  --publish 127.0.0.1:443:443 \
  --name gvm-server \
  gvm-server-v10:latest
# Monitor the logs
docker logs -f gvm-server
```
