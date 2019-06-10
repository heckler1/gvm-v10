# gvm-v10

This is a customized OpenVAS/Greebone Vulnerability Manager (GVM) v10 Docker container. It is based on the [Atomicorp Docker container](https://github.com/Atomicorp/openvas-docker), but at the time this repo was created, the Atomicorp image was running OpenVAS v9. However, this image is structured quite differently from the Atomicorp image.

The notable differences in this image stem primarily from the fact that the image does not run a GVM server anymore. Instead, on invocation, the image runs a vulnerability scan using the provided options.

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
