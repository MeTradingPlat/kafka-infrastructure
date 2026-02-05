# Kafka Infrastructure - MeTradingPlat

Repositorio centralizado para la infraestructura de Apache Kafka utilizada por todos los microservicios de MeTradingPlat.

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         KAFKA INFRASTRUCTURE                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌───────────┐      ┌───────────┐      ┌───────────┐                  │
│   │ Zookeeper │◄────►│   Kafka   │◄────►│ Kafka UI  │                  │
│   │  :2181    │      │ :9092     │      │  :8090    │                  │
│   └───────────┘      │ :29092    │      └───────────┘                  │
│                      └─────┬─────┘                                      │
│                            │                                            │
└────────────────────────────┼────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Producers   │  │    Consumers    │  │   Both          │
├───────────────┤  ├─────────────────┤  ├─────────────────┤
│ signal-       │  │ asset-mgmt      │  │ log-service     │
│ processing    │  │ notification    │  │ marketdata      │
└───────────────┘  └─────────────────┘  └─────────────────┘
```

## Topics

| Topic | Productor | Consumidor | Descripción |
|-------|-----------|------------|-------------|
| `signals` | signal-processing | asset-management | Señales de trading generadas |
| `logs` | signal-processing | log-service | Eventos y logs del sistema |
| `asset-state` | signal-processing | asset-management | Cambios de estado de activos |
| `order-requests` | signal-processing | marketdata | Solicitudes de órdenes |
| `logs.notifications` | log-service | notification | Notificaciones en tiempo real |
| `orders.updates` | marketdata | - | Actualizaciones de órdenes |
| `marketdata.stream` | marketdata | - | Stream de datos de mercado |
| `realtime-updates` | - | marketdata | Updates en tiempo real |

## Desarrollo Local

### Requisitos
- Docker
- Docker Compose

### Iniciar

```bash
# Levantar toda la infraestructura
docker-compose up -d

# Ver logs
docker-compose logs -f kafka

# Verificar topics
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### Crear topics manualmente

```bash
# Dar permisos al script
chmod +x scripts/create-topics.sh

# Ejecutar dentro del contenedor
docker exec kafka bash /scripts/create-topics.sh
```

### Puertos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| Kafka (interno) | 29092 | Para contenedores en la misma red |
| Kafka (externo) | 9092 | Para conexiones desde localhost |
| Zookeeper | 2181 | Coordinación de Kafka |
| Kafka UI | 8090 | Interfaz web de monitoreo |

## Configuración en Microservicios

### Desarrollo (localhost)

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
```

```python
KAFKA_BOOTSTRAP_SERVERS = "localhost:9092"
```

### Producción (Docker/K8s)

```yaml
spring:
  kafka:
    bootstrap-servers: kafka:29092
```

```python
KAFKA_BOOTSTRAP_SERVERS = "kafka:29092"
```

## CI/CD

El workflow de GitHub Actions (`.github/workflows/cd.yml`) despliega automáticamente:

1. Crea la red Docker `metradingplat-network`
2. Despliega Zookeeper
3. Despliega Kafka
4. Crea todos los topics necesarios
5. Despliega Kafka UI para monitoreo

### Ejecutar manualmente

```bash
# Desde GitHub Actions
gh workflow run cd.yml
```

## Monitoreo

### Kafka UI
Accede a `http://localhost:8090` para ver:
- Topics y mensajes
- Consumer groups
- Brokers
- Métricas

### Comandos útiles

```bash
# Listar topics
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Describir un topic
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic signals

# Ver mensajes de un topic
docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic signals --from-beginning

# Ver consumer groups
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --list

# Describir consumer group
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group activos-group
```

## Migración desde Microservicios

Si actualmente tienes la creación de Kafka en los workflows de otros microservicios, elimina esas secciones:

### Antes (en cada microservicio)
```yaml
# ❌ Eliminar esto de marketdata-service/cd.yml, etc.
- name: Run Kafka Infrastructure
  run: |
    docker run -d --name zookeeper ...
    docker run -d --name kafka ...
```

### Después
Los microservicios solo deben esperar que Kafka esté disponible, no crearlo.

## Troubleshooting

### Kafka no inicia
```bash
# Verificar logs
docker logs kafka

# Verificar que Zookeeper esté corriendo
docker logs zookeeper
```

### Topics no se crean
```bash
# Crear manualmente
docker exec kafka kafka-topics --bootstrap-server localhost:9092 \
  --create --topic nombre-topic --partitions 3 --replication-factor 1
```

### Conexión rechazada desde microservicios
1. Verificar que estén en la misma red Docker
2. Usar `kafka:29092` (no `localhost:9092`) desde otros contenedores
