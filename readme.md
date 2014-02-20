# Docker Registry (private)
This uses the `stackbrew/registry` as a base and adds basic auth via Nginx.

# Usage
To run a private registry, launch a container from this image and bind a volume
with your SSL cert and key and then specify environment variables to define the
certificate and key in the container.  For example:

`docker run -i -t -p 443 -v /path/to/cert_and_key:/opt/ssl -e SSL_CERT_PATH=/opt/ssl/cert.crt -e SSL_CERT_KEY_PATH=/opt/ssl/cert.key shipyard/private-registry`

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
* `SSL_CERT_PATH`: SSL Certificate path
* `SSL_CERT_KEY_PATH`: SSL Certificate key path

# Ports
* 80
* 443
* 5000

# Running on S3
To run with Amazon S3 as the backing store, you will need the following environment variables:

* `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID (make sure it has S3 access)
* `AWS_SECRET_KEY`: Your AWS Secret Key
* `S3_BUCKET`: Your S3 bucket to store images
* `SETTINGS_FLAVOR`: This must be set to `prod`
