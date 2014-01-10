# Docker Registry (private)
This uses the `stackbrew/registry` as a base and adds basic auth via Nginx.

# Maangement
There is a simple management application written in Flask that you can use
to manage registry users.  To access the management application, create a 
container from this image and visit `/manage`.

The default username is `admin` with a password of `docker`.

# Environment
* `ADMIN_PASSWORD`: Use a custom admin password (default: docker)
* `REGISTRY_NAME`: Custom name for registry (used when prompted for auth)

# Ports
* 80
* 443
* 5000

