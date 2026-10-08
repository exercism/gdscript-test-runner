FROM ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7 AS builder
ARG version=4.7.2

RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and unzip Godot
ADD https://downloads.godotengine.org/?version=${version}&flavor=stable&slug=linux.x86_64.zip&platform=linux.64 /tmp/godot.zip
RUN unzip -p /tmp/godot.zip > /usr/bin/godot && chmod +x /usr/bin/godot

FROM ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7 AS runner

RUN apt-get update && \
    apt-get install -y --no-install-recommends libfontconfig1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/bin/godot /usr/bin/godot

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
