FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
  curl \
  bash \
  sudo \
  ca-certificates

RUN useradd -m -s /bin/bash user && \
  echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER user
WORKDIR /home/user

RUN curl -fsSL https://raw.githubusercontent.com/borumbombum/init/main/bootstrap.sh | bash

CMD ["tmux", "attach", "-t", "OpencodeBot"]
