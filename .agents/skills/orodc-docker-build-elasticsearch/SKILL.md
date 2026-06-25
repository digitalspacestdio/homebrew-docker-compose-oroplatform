---
name: orodc-docker-build-elasticsearch
description: Switch Elasticsearch or OpenSearch to another version in OroDC. Use when the user needs a different search engine version, custom search image, or Elasticsearch/OpenSearch is incompatible with the CMS.
license: MIT
metadata:
  author: local
  scope: project
  internal: true
---

# Elasticsearch / OpenSearch Version

Change the `search` service image via `.env.orodc`. No custom Dockerfile in OroDC — use official Elastic or OpenSearch images.

## Compose Behavior

`compose/docker-compose.yml` service `search`:

```yaml
image: '${DC_ORO_SEARCH_IMAGE:-${DC_ORO_ELASTICSEARCH_IMAGE:-docker.elastic.co/elasticsearch/elasticsearch}:${DC_ORO_ELASTICSEARCH_VERSION:-9.2.0}}'
```

`DC_ORO_SEARCH_IMAGE` (full image ref) takes priority over split image+version vars.

## Switch Version — Elasticsearch

In `.env.orodc`:

```bash
DC_ORO_SEARCH_ENGINE=Elasticsearch
DC_ORO_SEARCH_VERSION=8.15.0
DC_ORO_SEARCH_IMAGE=docker.elastic.co/elasticsearch/elasticsearch:8.15.0
```

Known versions from `orodc init`: `9.2.0`, `8.15.0`, `8.10.3`, `7.17.0`.

Alternative (legacy vars from README):

```bash
DC_ORO_ELASTICSEARCH_VERSION=8.15.0
```

## Switch Version — OpenSearch

```bash
DC_ORO_SEARCH_ENGINE=OpenSearch
DC_ORO_SEARCH_VERSION=3.3.0
DC_ORO_SEARCH_IMAGE=opensearchproject/opensearch:3.3.0
```

Known versions from `orodc init`: `3.3.0`, `3.0.0`, `2.15.0`, `2.11.0`, `1.3.0`.

Magento projects often need OpenSearch instead of Elasticsearch.

## Version Not in Init List

1. Check image exists: `docker pull docker.elastic.co/elasticsearch/elasticsearch:X.Y.Z`
2. Set full image in `.env.orodc`:

```bash
DC_ORO_SEARCH_IMAGE=docker.elastic.co/elasticsearch/elasticsearch:X.Y.Z
DC_ORO_SEARCH_VERSION=X.Y.Z
```

3. Restart:

```bash
orodc down
orodc up -d
```

## OpenSearch Extra Env (if needed)

For OpenSearch 2.x+, add to `.docker-compose.user.yml` if security plugin blocks startup:

```yaml
services:
  search:
    environment:
      DISABLE_SECURITY_PLUGIN: "true"
      discovery.type: single-node
```

Default compose already sets `discovery.type: single-node` and `xpack.security.enabled: false` (Elasticsearch-oriented; OpenSearch may need overrides).

## Interactive Setup

```bash
orodc init
```

Step 3 — Search Engine Configuration.

## Verify

```bash
orodc ps
curl -s http://127.0.0.1:${DC_ORO_PORT_SEARCH:-9200}
orodc doctor
```

## CMS Notes

- **Oro Platform:** usually Elasticsearch 8.x or 9.x; check Oro release notes
- **Magento 2.4+:** OpenSearch preferred; set `DC_ORO_SEARCH_IMAGE=opensearchproject/opensearch:...`

## Data Volume Warning

Major search version changes may require reindexing or clearing `search-data` volume:

```bash
orodc down
docker volume rm <project>_search-data   # only if user accepts data loss
orodc up -d
```

## References

- `compose/docker-compose.yml` — `search` service
- `libexec/orodc/init.sh` — search engine prompts
- `compose/docker/doctor/default/search.yaml` — health checks
