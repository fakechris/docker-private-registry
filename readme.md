# Docker Registry (private)
This uses the `stackbrew/registry` as a base and adds basic auth via Nginx.

# Usage
To run a private registry, launch a container from this image and bind the SSL
certificate and key.  For example:

`docker run -i -t -p 443 -v /path/to/cert.crt:/etc/registry.crt -v /path/to/cert.key:/etc/registry.key shipyard/private-registry`

# SSL
Until https://github.com/dotcloud/docker/pull/2687 is fixed, a valid (from a 
recognized CA) SSL certificate is required.

# Mangement
There is a simple management application written in Flask that you can use
to manage registry users.  To access the management application, create a 
container from this image and visit `/manage`.

The default username is `admin` with a password of `docker`.  You can change
the password at run via environment variables (see below).

# Environment
* `ADMIN_PASSWORD`: Use a custom admin password (default: docker)
* `REGISTRY_NAME`: Custom name for registry (used when prompted for auth)

# Ports
* 80
* 443
* 5000

