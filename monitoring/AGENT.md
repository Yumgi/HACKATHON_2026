# AGENT.md — Monitoring (Prometheus + Grafana + Loki)

## Rôle

Centraliser la supervision des métriques et des logs de l'infrastructure ACME Corp.

## Containers

| Service | IP | Port | OS | Rôle |
|---------|----|------|----|------|
| Prometheus | 10.20.0.40 | 9090 | Debian 12 | Scrape métriques, évaluation alertes |
| Alertmanager | 10.20.0.40 | 9093 | Debian 12 | Routage des alertes |
| Grafana | 10.20.0.41 | 3000 | Ubuntu 22.04 | Dashboards (Prometheus + Loki) |
| Loki | 10.20.0.42 | 3100 | Debian 12 | Stockage et requête de logs |
| Promtail | chaque hôte | 9080 | — | Agent collecte logs → Loki |
| node_exporter | chaque hôte | 9100 | — | Métriques système Linux |
| postgres_exporter | 10.20.0.20 | 9187 | — | Métriques PostgreSQL |

## Sources de logs centralisées

| Source | Job Promtail | Contenu |
|--------|-------------|---------|
| `syslog` | `syslog` | Kernel, cron, services système |
| `auth.log` | `auth` | SSH, sudo, PAM |
| Traefik | `traefik` | Requêtes HTTP, codes, latences |
| FreeIPA / 389-ds | `freeipa` | Connexions LDAP, échecs d'auth |

## Alertes actives — `prometheus/alerts/rules.yml`

| Alerte | Seuil | Sévérité |
|--------|-------|----------|
| `InstanceDown` | target DOWN > 2 min | critical |
| `HighCPULoad` | CPU > 80% / 5 min | warning |
| `DiskSpaceLow` | disque < 15% | warning |
| `HighMemoryUsage` | RAM > 85% / 5 min | warning |
| `PostgreSQLDown` | pg_up == 0 > 1 min | critical |
| `PostgreSQLTooManyConnections` | connexions > 80 | warning |
| `TraefikDown` | traefik UP == 0 > 1 min | critical |

## Dashboards Grafana provisionnés

- `acme-overview.json` — Vue globale infrastructure (CPU, RAM, réseau, disque)
- `acme-logs.json` — Explorateur Loki par service

Ajouter un dashboard :
1. Exporter le JSON depuis Grafana UI
2. Placer dans `monitoring/grafana/dashboards/`
3. `ansible-playbook playbooks/monitoring.yml --tags configure --limit grafana`

## Requêtes Loki utiles

```logql
# Connexions LDAP échouées
{job="freeipa"} |= "INVALID_CREDENTIALS"

# Requêtes Traefik 5xx
{job="traefik"} | json | status >= 500

# Erreurs SSH (brute force)
{job="auth"} |= "Failed password"

# Activité syslog critique
{job="syslog"} | logfmt | level="crit"
```

## Ajouter une alerte Prometheus

1. Éditer `monitoring/prometheus/alerts/rules.yml`
2. `ansible-playbook playbooks/monitoring.yml --tags alerts`
3. Vérifier : `curl http://10.20.0.40:9090/api/v1/rules`

## Accès

| Interface | URL (via Traefik) | URL directe |
|-----------|-------------------|-------------|
| Grafana | https://grafana.acme.local | http://10.20.0.41:3000 |
| Prometheus | — (interne) | http://10.20.0.40:9090 |
| Alertmanager | — (interne) | http://10.20.0.40:9093 |
| Loki | — (interne) | http://10.20.0.42:3100 |
