#!/bin/bash

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready..."
sleep 10

KAFKA_BOOTSTRAP_SERVER=${KAFKA_BOOTSTRAP_SERVER:-kafka:29092}

# Function to create topic if it doesn't exist
create_topic() {
    local topic_name=$1
    local partitions=${2:-3}
    local replication=${3:-1}

    echo "Creating topic: $topic_name (partitions: $partitions, replication: $replication)"

    kafka-topics --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
        --create \
        --if-not-exists \
        --topic $topic_name \
        --partitions $partitions \
        --replication-factor $replication
}

# MeTradingPlat Topics
echo "========================================="
echo "Creating MeTradingPlat Kafka Topics"
echo "========================================="

# Signal Processing Service -> Asset Management Service
create_topic "signals" 3 1

# Signal Processing Service -> Log Service
create_topic "logs" 3 1

# Signal Processing Service -> Asset Management Service
create_topic "asset-state" 3 1

# Signal Processing Service -> MarketData Service
create_topic "order-requests" 3 1

# Log Service -> Notification Service
create_topic "logs.notifications" 3 1

# MarketData Service outputs
create_topic "orders.updates" 3 1
create_topic "marketdata.stream" 3 1

# Real-time updates
create_topic "realtime-updates" 3 1

echo "========================================="
echo "All topics created successfully!"
echo "========================================="

# List all topics
echo ""
echo "Current topics:"
kafka-topics --bootstrap-server $KAFKA_BOOTSTRAP_SERVER --list
