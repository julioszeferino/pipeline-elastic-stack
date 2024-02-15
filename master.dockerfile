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

# Cria o diretorio
RUN mkdir -p /opt/elasticsearch && \
    mkdir -p /opt/kibana && \
    mkdir -p /opt/logstash  && \
    mkdir -p /opt/logstash/files && \
    mkdir -p /opt/mysql

# Download do Elasticsearch
RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.3-linux-x86_64.tar.gz -o elasticsearch-7.9.3-linux-x86_64.tar.gz \
    && tar xvzf elasticsearch-7.9.3-linux-x86_64.tar.gz --directory /opt/elasticsearch --strip-components 1 \
    && rm -rf elasticsearch-7.9.3-linux-x86_64.tar.gz

# Download do Kibana
RUN curl https://artifacts.elastic.co/downloads/kibana/kibana-7.9.3-linux-x86_64.tar.gz -o kibana-7.9.3-linux-x86_64.tar.gz \
    && tar xvzf kibana-7.9.3-linux-x86_64.tar.gz --directory /opt/kibana --strip-components 1 \
    && rm -rf kibana-7.9.3-linux-x86_64.tar.gz

# Download do Logstash
RUN curl https://artifacts.elastic.co/downloads/logstash/logstash-7.9.3.tar.gz -o logstash-7.9.3.tar.gz \
    && tar xvzf logstash-7.9.3.tar.gz --directory /opt/logstash --strip-components 1 \
    && rm -rf logstash-7.9.3.tar.gz

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

# RUN sysctl -w vm.max_map_count=262144
# RUN sysctl --system

# Prepara o ambiente com Elastic Search
FROM base as elasticsearch

# Variável de ambiente do JAVA_HOME
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ENV ELASTIC_HOME=/opt/elasticsearch
ENV KIBANA_HOME=/opt/kibana
ENV LOGSTASH_HOME=/opt/logstash
ENV PATH=$PATH:${ELASTIC_HOME}/bin:${JAVA_HOME}/bin:${KIBANA_HOME}/bin:${LOGSTASH_HOME}/bin

COPY ./elasticsearch/elasticsearch-master.yml ${ELASTIC_HOME}/config/elasticsearch.yml
COPY ./elasticsearch/kibana.yml ${KIBANA_HOME}/config/kibana.yml
COPY ./elasticsearch/mysql-connector-java-5.1.49.jar /opt/mysql/mysql-connector-java-5.1.49.jar
COPY ./elasticsearch/logstash_sensor_data_http.conf /opt/logstash/files/logstash_sensor_data_http.conf
COPY ./dados/* /opt/logstash/files/

# permissão de execução (moveu para antes da troca de usuário)
RUN chmod +x /opt/logstash/files/carga_dados_sensores.sh

# cria um usuario para rodar o elasticsearch
RUN useradd -ms /bin/bash elasticsearch && \
    chown -R elasticsearch:elasticsearch ${ELASTIC_HOME} && \
    chown -R elasticsearch:elasticsearch ${KIBANA_HOME} && \
    chown -R elasticsearch:elasticsearch ${LOGSTASH_HOME} && \
    chown -R elasticsearch:elasticsearch /opt/mysql

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

# Adiciona o kibana ao PATH
RUN echo "export KIBANA_HOME=${KIBANA_HOME}" >> "/home/elasticsearch/.bashrc" && \
    echo "export PATH=$PATH:${KIBANA_HOME}/bin" >> "/home/elasticsearch/.bashrc"

# Adiciona o logstash ao PATH
RUN echo "export LOGSTASH_HOME=${LOGSTASH_HOME}" >> "/home/elasticsearch/.bashrc" && \
    echo "export PATH=$PATH:${LOGSTASH_HOME}/bin" >> "/home/elasticsearch/.bashrc"

EXPOSE 9200 9300 5601