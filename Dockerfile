FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64

RUN apt-get update && \
    apt-get install -y coreutils wget zip libfontconfig1 && \
    apt-get purge --auto-remove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and unzip Godot v4.4.1
RUN wget https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip && \
    unzip Godot_v4.4.1-stable_linux.x86_64.zip && \
    mv Godot_v4.4.1-stable_linux.x86_64 /usr/bin/godot && \
    rm Godot_v4.4.1-stable_linux.x86_64.zip

WORKDIR /opt/exercism/gdscript/test-runner
COPY . .
ENTRYPOINT ["/opt/exercism/gdscript/test-runner/bin/run.sh"]
