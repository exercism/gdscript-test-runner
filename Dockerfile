FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c AS builder
ARG version=4.7.2

RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and unzip Godot
ADD https://downloads.godotengine.org/?version=${version}&flavor=stable&slug=linux.x86_64.zip&platform=linux.64 /tmp/godot.zip
RUN unzip -p /tmp/godot.zip > /usr/bin/godot && chmod +x /usr/bin/godot

FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c AS runner

RUN apt-get update && \
    apt-get install -y --no-install-recommends libfontconfig1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/bin/godot /usr/bin/godot

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
