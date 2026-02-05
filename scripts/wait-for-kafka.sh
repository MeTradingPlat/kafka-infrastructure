#!/bin/bash

KAFKA_BOOTSTRAP_SERVER=${KAFKA_BOOTSTRAP_SERVER:-localhost:9092}
MAX_RETRIES=${MAX_RETRIES:-30}
RETRY_INTERVAL=${RETRY_INTERVAL:-5}

echo "Waiting for Kafka at $KAFKA_BOOTSTRAP_SERVER..."

for i in $(seq 1 $MAX_RETRIES); do
    if kafka-broker-api-versions --bootstrap-server $KAFKA_BOOTSTRAP_SERVER > /dev/null 2>&1; then
        echo "Kafka is ready!"
        exit 0
    fi
    echo "Attempt $i/$MAX_RETRIES - Kafka not ready yet, waiting ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
done

echo "Kafka did not become ready in time"
exit 1
