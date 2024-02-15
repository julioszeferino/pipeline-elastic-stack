FROM ubuntu:18.04 as base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo \
      curl \
      vim \
      nano \
      unzip \
      rsync \
      openjdk-11-jdk \
      build-essential \
      software-properties-common \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV ELASTICSEARCH_HOME="/opt/elasticsearch"

# Cria o diretorio
RUN mkdir -p /opt/elasticsearch

# Download do Elasticsearch
RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.3-linux-x86_64.tar.gz -o elasticsearch-7.9.3-linux-x86_64.tar.gz \
    && tar xvzf elasticsearch-7.9.3-linux-x86_64.tar.gz --directory /opt/elasticsearch --strip-components 1 \
    && rm -rf elasticsearch-7.9.3-linux-x86_64.tar.gz

# Configuracoes de memoria
RUN echo "vm.max_map_count=262144" >> /etc/sysctl.conf
RUN echo 'DefaultLimitNOFILE=65536' /etc/systemd/user.conf
RUN echo 'DefaultLimitNOFILE=65536' /etc/systemd/system.conf
RUN echo "* soft nofile 65536" >> /etc/security/limits.conf && \
    echo "* hard nofile 65536" >> /etc/security/limits.conf && \
    echo "elasticsearch soft nofile 65536" >> /etc/security/limits.conf && \
    echo "elasticsearch hard nofile 65536" >> /etc/security/limits.conf && \
    echo "elasticsearch memlock unlimited" >> /etc/security/limits.conf

# Entrypoint script
COPY ./entrypoint-script.sh /opt/elasticsearch/entrypoint.sh

# permissão de execução (moveu para antes da troca de usuário)
RUN chmod +x /opt/elasticsearch/entrypoint.sh

RUN sysctl -w vm.max_map_count=262144
RUN sysctl --system

# Prepara o ambiente com Elastic Search
FROM base as elasticsearch

# Variável de ambiente do JAVA_HOME
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ENV ELASTIC_HOME=/opt/elasticsearch
ENV PATH=$PATH:${ELASTIC_HOME}/bin:${JAVA_HOME}/bin

COPY ./elasticsearch/elasticsearch-node.yml ${ELASTIC_HOME}/config/elasticsearch.yml

# cria um usuario para rodar o elasticsearch
RUN useradd -ms /bin/bash elasticsearch && \
    chown -R elasticsearch:elasticsearch ${ELASTIC_HOME}

# Define o usuario que irá rodar o elasticsearch
USER elasticsearch

# Define o diretorio de trabalho
WORKDIR ${ELASTIC_HOME}

# Adiciona o JAVA_HOME ao PATH
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> "/home/elasticsearch/.bashrc" && \
    echo "export PATH=$PATH:${JAVA_HOME}/bin" >> "/home/elasticsearch/.bashrc"

# Adiciona o elasticsearch ao PATH
RUN echo "export ELASTIC_HOME=${ELASTIC_HOME}" >> "/home/elasticsearch/.bashrc" && \
    echo "export PATH=$PATH:${ELASTIC_HOME}/bin" >> "/home/elasticsearch/.bashrc"

EXPOSE 9200 9300 5601