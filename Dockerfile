FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
ARG version=4.7.2

RUN apt-get update && \
    apt-get install -y libfontconfig1 unzip && \
    apt-get purge --auto-remove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and unzip Godot
ADD https://downloads.godotengine.org/?version=${version}&flavor=stable&slug=linux.x86_64.zip&platform=linux.64 /tmp/godot.zip
RUN unzip -d /usr/bin/ /tmp/godot.zip && rm /tmp/godot.zip && mv /usr/bin/Godot_v${version}-stable_linux.x86_64 /usr/bin/godot

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
