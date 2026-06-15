---
name: orodc-docker-build-rabbitmq
description: Switch RabbitMQ to another version in OroDC. Use when the user needs a newer RabbitMQ, a custom RabbitMQ image, or the default oroinc/rabbitmq image is incompatible.
license: MIT
metadata:
  author: local
  scope: project
---

# RabbitMQ Version

Change the `mq` service image. Default in compose: `oroinc/rabbitmq:3.9-1-management-alpine`.

## Important

`DC_ORO_RABBITMQ_IMAGE` is saved by `orodc init` to `.env.orodc`, but `compose/docker-compose.yml` does **not** substitute it into the `mq` service image. Use one of the methods below.

## Method 1 — `.docker-compose.user.yml` (Recommended)

Create or edit `app/.docker-compose.user.yml` in the project:

```yaml
services:
  mq:
    image: rabbitmq:3.13-management-alpine
```

Restart:

```bash
orodc down
orodc up -d
```

OroDC auto-includes this file when present (`bin/orodc` adds `-f app/.docker-compose.user.yml`).

## Method 2 — `orodc init` + user override

`orodc init` step 5 offers versions `3.13`, `3.12`, `3.11` and writes:

```bash
DC_ORO_RABBITMQ_VERSION=3.13
DC_ORO_RABBITMQ_IMAGE=rabbitmq:3.13-management-alpine
```

Still add `.docker-compose.user.yml` with the same image — env vars alone do not change compose.

## Method 3 — Official Oro Image Variants

For Oro-specific plugins, try other `oroinc/rabbitmq` tags:

```yaml
services:
  mq:
    image: oroinc/rabbitmq:3.13-management-alpine
```

Check available tags: `docker search oroinc/rabbitmq` or Docker Hub.

## Method 4 — Custom Built Image

```dockerfile
FROM rabbitmq:3.13-management-alpine
# add plugins, configs
```

```bash
docker build -t myrabbitmq:3.13 .
```

```yaml
# app/.docker-compose.user.yml
services:
  mq:
    image: myrabbitmq:3.13
```

## MQ Credentials

Defaults (from compose):

```bash
DC_ORO_MQ_USER=app
DC_ORO_MQ_PASSWORD=app
```

Application DSN (when RabbitMQ is used):

```bash
DC_ORO_MQ_URI=amqp://app:app@mq:5672/
```

Community Oro defaults to `dbal:` — set `DC_ORO_MQ_URI` explicitly for RabbitMQ.

## Verify

```bash
orodc ps
# Management UI: http://127.0.0.1:${DC_ORO_PORT_MQ:-15672}
curl -u app:app http://127.0.0.1:15672/api/overview
orodc doctor
```

## Tap Maintainer

To wire `DC_ORO_RABBITMQ_IMAGE` natively, update `compose/docker-compose.yml`:

```yaml
mq:
  image: '${DC_ORO_RABBITMQ_IMAGE:-oroinc/rabbitmq:3.9-1-management-alpine}'
```

Then bump Formula revision and reinstall.

## References

- `compose/docker-compose.yml` — `mq` service
- `libexec/orodc/init.sh` — RabbitMQ configuration step
- `README.md` — custom image env vars section
