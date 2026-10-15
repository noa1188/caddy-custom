# Caddy Custom Build

Custom Caddy Docker image with plugins:
- github.com/caddy-dns/cloudflare
- github.com/caddy-dns/desec
- github.com/WeidiDeng/caddy-cloudflare-ip
- github.com/fvbommel/caddy-combine-ip-ranges
- github.com/mholt/caddy-webdav

## Build

```bash
docker build -t caddy-custom .
```

Override version:
```bash
docker build --build-arg CADDY_VERSION=2.12.0 -t caddy-custom .
```

## GitHub Actions

- Scheduled check for upstream Caddy releases
- Build and push to Docker Hub on push / manual dispatch
- Release tag on version bump

Set secrets:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
