# mmw-agent Docker image

This repository automatically packages signed releases from
[`mmwx-group/mmwx-agent`](https://github.com/mmwx-group/mmwx-agent) on top of
the official mmw-agent container runtime.

The workflow checks upstream once per hour. For every new release it:

1. Downloads the Linux amd64 and arm64 Agent binaries and signed manifests.
2. Verifies all SHA-256 checksums and the manifest-to-binary binding.
3. Builds both platforms and smoke-tests the bundled Guard on the native amd64 runner.
4. Publishes a multi-platform image to GHCR only if every check passes.

## Image

```text
ghcr.io/menzhu/mmw-agent-docker:latest
```

Versioned tags are also published in both forms, for example `v0.6.8` and
`0.6.8`.

## Usage

Use the same environment variables, host networking, and persistent mounts as
the official image. Only change the image field in Compose:

```yaml
services:
  mmw-agent:
    image: ghcr.io/menzhu/mmw-agent-docker:latest
    network_mode: host
    restart: unless-stopped
```

For controlled rollouts, pin a versioned tag instead of `latest`.

## Trust model

The base image is pinned by digest. Agent binaries and signed manifests come
from the upstream GitHub Release. The Guard is inherited from the pinned
official base image. Both platform manifests are verified before building; an
incompatible amd64 release also fails the native Guard smoke test and is not
published.
