# Deploying Docker registry server for the MaxScale

## Requirements for the registry

The [Docker registry](https://docs.docker.com/registry/) is a service that allows to store and extract the image containers. For MaxScale such registry is needed for the system testing during the CI-process.

In our setup the registry is required to process requests from up to 3 build servers and up to 10 clients at the same time. The registry itself and its' contents can be rebuild at any time. This way we do not need to provide high availability for such registry and the simplest setup suites our needs.

The registry should not be put public. For our installation simple basic HTTP authentication should be sufficient.

The installation will include only the Docker registry service that is run in the Docker Swarm mode.

- Docker registry service.

The official documentation contains a [recipe](https://docs.docker.com/registry/#run-an-externally-accessible-registry) for such setup.

## Dependency installation

The following dependencies are needed to be installed:

- Docker. Follow official installation [instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

Switch Docker into the Swarm mode.

```
docker swarm init
```

## Authentication

Create a password file that will contain all the required passwords:

```
sudo mkdir /home/docker-registry/auth
sudo touch /home/docker-registry/auth/docker-registry.htpasswd
sudo htpasswd -B /home/docker-registry/auth/docker-registry.htpasswd USER
```

The password will be asked on the command prompt.

## Docker registry

In current MaxScale CI setup the Docker is running in the Swarm mode. This mode will be used to deploy the registry. See the docker-registry.yaml file for stack configuration.

In order to deploy the service the following commands are needed:

```
sudo mkdir -p /home/docker-registry/registry
docker stack deploy -c docker-registry.yaml maxscale-docker-registry
```

## Nginx configuration

Nginx server will redirect to the 5000 port that is used to provide registry services. This part is not required, but used for the convenience only.

Copy the `docker-registry.nginx` file to the `/etc/nginx/sites-available`, create the symbolic link to this file into the directory `/etc/nginx/sites-enabled` and reconfigure the Nginx.
