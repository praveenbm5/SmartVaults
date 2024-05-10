FROM ubuntu:22.04
RUN apt update && apt install -y software-properties-common
RUN apt update && \
   apt install -y \ 
   wget tar git python3 python3-pip jq nano
WORKDIR /root/projects

# Change this to match your platform
# https://bitcoincore.org/bin/bitcoin-core-25.0/

# RUN wget -O bitcoin.tar.gz https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz
# RUN wget -O bitcoin.tar.gz https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-arm64-apple-darwin.tar.gz
# RUN wget -O bitcoin.tar.gz https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-apple-darwin.tar.gz
# RUN wget -O bitcoin.tar.gz https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-arm-linux-gnueabihf.tar.gz
RUN wget -O bitcoin.tar.gz https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-aarch64-linux-gnu.tar.gz

RUN tar xzf bitcoin.tar.gz
ENV PATH="/root/projects/bitcoin-25.0/bin:${PATH}"

RUN pip3 install cryptos

#RUN git clone <repository_url>
COPY . SmartVaults
WORKDIR /root/projects/SmartVaults

USER root

CMD ["/bin/bash"]