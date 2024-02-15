#!/bin/bash

ELASTIC_WORKLOAD=$1

echo "ELASTIC_WORKLOAD: $ELASTIC_WORKLOAD"

/etc/init.d/ssh start

echo "Initializing elasticsearch..."

if [ "$ELASTIC_WORKLOAD" == "master" ];
then
    # inicializa o elastic master
    /opt/elasticsearch/bin/elasticsearch > /dev/null 2>&1 &

    sleep 10

    echo "Waiting for elasticsearch to start..."
    while true; do
        curl -s -XGET "http://localhost:9200" > /dev/null
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 5
    done

    echo "Elasticsearch started"

    sleep 10


    echo "Initializing kibana..."

    # inicializa o kibana
    /opt/kibana/bin/kibana > /dev/null 2>&1 &

    while true; do
        curl -s -XGET "http://localhost:5601" > /dev/null
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 5
    done

    echo "Kibana started"

    sleep 30

    echo "Creating index pattern..."

    # fazer um post na api do kibana para criar o index pattern
    curl -XPUT "http://localhost:9200/_template/sensor_data_template" -H 'Content-Type: application/json' -d '
    {
    "index_patterns": [
        "dados_sensores*"
    ],
    "settings": {
        "number_of_replicas": "1",
        "number_of_shards": "5"
    },
    "mappings": {
        "properties": {
        "sensor_id": {
            "type": "integer"
        },
        "tipo_sensor": {
            "type": "keyword",
            "fields": {
            "analyzed": {
                "type": "text"
            }
            }
        },
        "cliente": {
            "type": "keyword",
            "fields": {
            "analyzed": {
                "type": "text"
            }
            }
        },
        "departamento": {
            "type": "keyword",
            "fields": {
            "analyzed": {
                "type": "text"
            }
            }
        },
        "nome_edificio": {
            "type": "keyword",
            "fields": {
            "analyzed": {
                "type": "text"
            }
            }
        },
        "sala": {
            "type": "keyword",
            "fields": {
            "analyzed": {
                "type": "text"
            }
            }
        },
        "andar": {
            "type": "keyword",
            "fields": {
            "analyzed": {
                "type": "text"
            }
            }
        },
        "localidade_andar": {
            "type": "keyword",
            "fields": {
            "analyzed": {
                "type": "text"
            }
            }
        },
        "localidade": {
            "type": "geo_point"
        },
        "time": {
            "type": "date"
        },
        "leitura": {
            "type": "double"
        }
        }
    }
    }'

    sleep 5
    
    echo "Initializing logstash..."

    # inicializa o logstash com a pipeline
    /opt/logstash/bin/logstash -f /opt/logstash/files/logstash_sensor_data_http.conf

elif [ "$ELASTIC_WORKLOAD" == "data" ];
then
    # inicializa o elastic data
    /opt/elasticsearch/bin/elasticsearch > /dev/null 2>&1 &

else
    echo "Invalid ELASTIC_WORKLOAD"
    exit 1
fi
tail -f /dev/null
