FROM ubuntu:22.04

RUN apt-get update
RUN apt-get install -y jq coreutils wget zip libfontconfig1
# Download and unzip Godot v4.0.1
RUN wget https://downloads.tuxfamily.org/godotengine/4.0.1/Godot_v4.0.1-stable_linux.x86_64.zip
RUN unzip Godot_v4.0.1-stable_linux.x86_64.zip
RUN mv Godot_v4.0.1-stable_linux.x86_64 /usr/bin/godot
RUN rm Godot_v4.0.1-stable_linux.x86_64.zip

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
