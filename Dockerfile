# syntax=docker/dockerfile:1
ARG BASE_IMAGE=ghcr.io/iluobei/mmw-agent@sha256:5300b447e1ea9cfdcb07aee5423cae4b52f888370b1e30fdb59e91bd19f2ddeb
FROM ${BASE_IMAGE}

ARG TARGETARCH
ARG VERSION

COPY assets/mmw-agent-linux-${TARGETARCH} /usr/local/bin/mmw-agent
COPY assets/mmw-agent-linux-${TARGETARCH}.manifest /usr/local/share/mmwx-guard/agent.manifest

RUN chmod 0755 /usr/local/bin/mmw-agent \
    && chmod 0644 /usr/local/share/mmwx-guard/agent.manifest

LABEL org.opencontainers.image.title="mmw-agent auto image" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="https://github.com/menzhu/mmw-agent-docker" \
      org.opencontainers.image.base.name="ghcr.io/iluobei/mmw-agent:latest" \
      org.opencontainers.image.base.digest="sha256:5300b447e1ea9cfdcb07aee5423cae4b52f888370b1e30fdb59e91bd19f2ddeb" \
      org.opencontainers.image.description="Signed upstream mmw-agent release on the official container runtime"
