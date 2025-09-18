# Redis Helm Chart

A production-ready Helm chart for deploying Redis on Kubernetes.

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 7.2.5](https://img.shields.io/badge/AppVersion-7.2.5-informational?style=flat-square)

## Features

- **Multiple Architectures**: Standalone or Master-Slave replication
- **Persistence**: Optional persistent storage with PVC
- **Security**: Password authentication and security contexts
- **Health Checks**: Configurable liveness and readiness probes
- **Metrics**: Prometheus metrics exporter support
- **High Availability**: Sentinel support for automatic failover
- **Flexible Configuration**: Extensive customization options
- **Production Ready**: Sensible defaults for production use

## Quick Start

### Install Chart

```bash
# Add repository
helm repo add redis https://yourusername.github.io/redis-helm-chart/
helm repo update

# Install with default configuration
helm install my-redis redis/redis

# Install with custom values
helm install my-redis redis/redis -f values.yaml

# Install in specific namespace
helm install my-redis redis/redis -n redis-system --create-namespace
```

### Uninstall Chart

```bash
helm uninstall my-redis
```

## Architecture Modes

### Standalone Mode (Default)

Single Redis instance, suitable for development and simple caching:

```yaml
architecture: standalone
replicaCount: 1
```

### Replication Mode

Master-slave setup for read scaling:

```yaml
architecture: replication
master:
  persistence:
    enabled: true
    size: 10Gi
replica:
  replicaCount: 2
  persistence:
    enabled: true
    size: 10Gi
```

## Configuration Examples

### Basic Configuration

```yaml
# values.yaml
auth:
  enabled: true
  password: "MySecurePassword123!"

persistence:
  enabled: true
  size: 8Gi

resources:
  requests:
    memory: 256Mi
    cpu: 100m
  limits:
    memory: 512Mi
    cpu: 500m
```

### Production Configuration

```yaml
# production-values.yaml
architecture: replication
statefulset: true

auth:
  enabled: true
  password: "VerySecurePassword456!"

master:
  persistence:
    enabled: true
    size: 50Gi
    storageClass: fast-ssd
  resources:
    requests:
      memory: 1Gi
      cpu: 500m
    limits:
      memory: 2Gi
      cpu: 1000m

replica:
  replicaCount: 3
  persistence:
    enabled: true
    size: 50Gi
    storageClass: fast-ssd
  resources:
    requests:
      memory: 512Mi
      cpu: 250m
    limits:
      memory: 1Gi
      cpu: 500m

metrics:
  enabled: true

redis:
  extraConfig: |
    maxmemory 2gb
    maxmemory-policy allkeys-lru
    save 900 1
    save 300 10
    save 60 10000
```

### High Availability with Sentinel

```yaml
architecture: replication
sentinel:
  enabled: true
  replicaCount: 3
  quorum: 2
```

## Accessing Redis

### Get Password

```bash
export REDIS_PASSWORD=$(kubectl get secret my-redis-secret -o jsonpath="{.data.redis-password}" | base64 -d)
echo $REDIS_PASSWORD
```

### Port Forwarding

```bash
kubectl port-forward svc/my-redis 6379:6379
```

### Connect with redis-cli

```bash
# Local connection
redis-cli -h localhost -p 6379 -a $REDIS_PASSWORD

# From another pod
kubectl run -it --rm redis-client --image=redis:7.2.5-alpine -- redis-cli -h my-redis -a $REDIS_PASSWORD
```

## Common Operations

### Backup Data

```bash
# Create backup
kubectl exec -it my-redis-0 -- redis-cli -a $REDIS_PASSWORD --rdb /data/backup.rdb BGSAVE

# Copy backup locally
kubectl cp my-redis-0:/data/backup.rdb ./redis-backup.rdb
```

### Restore Data

```bash
# Copy backup to pod
kubectl cp ./redis-backup.rdb my-redis-0:/data/dump.rdb

# Restart Redis
kubectl delete pod my-redis-0
```

### Monitor Redis

```bash
# Redis INFO
kubectl exec -it my-redis-0 -- redis-cli -a $REDIS_PASSWORD INFO

# Monitor commands
kubectl exec -it my-redis-0 -- redis-cli -a $REDIS_PASSWORD MONITOR

# Check memory usage
kubectl exec -it my-redis-0 -- redis-cli -a $REDIS_PASSWORD INFO memory
```

### Flush Data

```bash
# Flush current database
kubectl exec -it my-redis-0 -- redis-cli -a $REDIS_PASSWORD FLUSHDB

# Flush all databases
kubectl exec -it my-redis-0 -- redis-cli -a $REDIS_PASSWORD FLUSHALL
```

## Metrics and Monitoring

Enable Prometheus metrics:

```yaml
metrics:
  enabled: true
```

Access metrics:

```bash
kubectl port-forward svc/my-redis-metrics 9121:9121
curl http://localhost:9121/metrics
```

## Configuration Parameters

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `architecture` | Redis architecture (`standalone` or `replication`) | `standalone` |
| `auth.enabled` | Enable authentication | `true` |
| `auth.password` | Redis password | `RedisPassword123!` |
| `auth.existingSecret` | Use existing secret | `""` |
| `statefulset` | Use StatefulSet instead of Deployment | `true` |
| `replicaCount` | Number of Redis replicas (standalone mode) | `1` |

### Image Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.registry` | Redis image registry | `docker.io` |
| `image.repository` | Redis image repository | `redis` |
| `image.tag` | Redis image tag | `7.2.5-alpine` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Persistence Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistence | `true` |
| `persistence.size` | PVC size | `8Gi` |
| `persistence.storageClassName` | Storage class | `""` |
| `persistence.accessMode` | Access mode | `ReadWriteOnce` |

### Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `6379` |
| `service.nodePort` | Node port (if type is NodePort) | `""` |
| `service.loadBalancerIP` | LoadBalancer IP | `""` |

### Resource Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests.memory` | Memory request | `256Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |

### Metrics Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `metrics.enabled` | Enable metrics exporter | `false` |
| `metrics.image.repository` | Exporter image repository | `oliver006/redis_exporter` |
| `metrics.image.tag` | Exporter image tag | `v1.58.0` |
| `metrics.port` | Metrics port | `9121` |

See [values.yaml](values.yaml) for complete configuration options.

## Troubleshooting

### Pod Stuck in Pending

Check if PVC can be provisioned:
```bash
kubectl describe pvc
kubectl get storageclass
```

### Authentication Failed

Verify password:
```bash
kubectl get secret my-redis-secret -o yaml
```

### Connection Refused

Check service and pod status:
```bash
kubectl get svc
kubectl get pods
kubectl logs my-redis-0
```

### Performance Issues

Check Redis metrics:
```bash
# Memory usage
kubectl exec -it my-redis-0 -- redis-cli -a $REDIS_PASSWORD INFO memory

# Check slow log
kubectl exec -it my-redis-0 -- redis-cli -a $REDIS_PASSWORD SLOWLOG GET 10
```

## Development

### Testing

```bash
# Dry run
helm install my-redis . --dry-run --debug

# Template rendering
helm template my-redis .

# Lint chart
helm lint .
```

### Building

```bash
# Package chart
helm package .

# Create index
helm repo index . --url https://yourusername.github.io/redis-helm-chart/
```

## Requirements

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support (for persistence)

## License

This chart is provided under the MIT License.

## Support

For issues and contributions, please visit the [GitHub repository](https://github.com/yourusername/redis-helm-chart).

---

**Note**: This is a production-ready Helm chart for Redis. Always review and test configurations before deploying to production environments.s