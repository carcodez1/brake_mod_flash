FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-avr \
    avr-libc \
    make \
    git \
    x11-utils \
    xauth \
    xvfb \
    tk \
    curl \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# Official Arduino CLI installer
RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh && \
    mv ./bin/arduino-cli /usr/local/bin/arduino-cli && \
    chmod +x /usr/local/bin/arduino-cli

WORKDIR /app
COPY . /app

RUN pip install --upgrade pip && pip install -r requirements.txt

RUN arduino-cli config init && \
    arduino-cli core update-index && \
    arduino-cli core install arduino:avr

CMD ["bash"]
