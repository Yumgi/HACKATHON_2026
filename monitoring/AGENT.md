# AGENT.md — Monitoring (Prometheus + Grafana + Loki)

## Rôle de ce module

Centraliser la supervision, les métriques et les logs de l'infrastructure ACME Corp.

## Composants

| Composant | Port | Rôle |
|-----------|------|------|
| Prometheus | 9090 | Scrape métriques, évaluation alertes |
| Alertmanager | 9093 | Routage et envoi des alertes |
| Grafana | 3000 | Dashboards métriques + logs |
| Loki | 3100 | Stockage et requête de logs |
| Promtail | — | Agent collecte logs (sur chaque hôte) |
| node_exporter | 9100 | Métriques système Linux |
| postgres_exporter | 9187 | Métriques PostgreSQL |

## Sources de logs centralisées (minimum 2 requis)

1. **Traefik access.log** — via Promtail → Loki (requêtes HTTP, codes, latences)
2. **Application Flask** — logs structurés JSON → Promtail → Loki (auth, erreurs, actions)
3. **Syslog système** — via Promtail → Loki (SSH, cron, kernel)
4. **FreeIPA / 389-ds** — via Promtail → Loki (connexions LDAP, auth failures)

## Alertes actives (minimum 2 requis)

Voir `prometheus/alerts/rules.yml` :
- `InstanceDown` — un hôte surveillé est inaccessible
- `HighCPULoad` — CPU > 80% pendant 5 min
- `DiskSpaceLow` — espace disque < 15%
- `PostgreSQLDown` — base de données inaccessible
- `AppHighErrorRate` — taux d'erreurs HTTP 5xx > 5%
- `BackupJobFailed` — job Bareos échoué (via log Loki)

## Dashboards Grafana

- `acme-overview.json` — Vue globale infrastructure (CPU, RAM, réseau)
- `acme-app.json` — Métriques application (requêtes/s, erreurs, latence)
- `acme-logs.json` — Explorateur Loki avec filtres par service

## Requêtes Loki utiles

```logql
# Erreurs application
{job="acme-app"} |= "ERROR"

# Connexions LDAP échouées
{job="freeipa"} |= "INVALID_CREDENTIALS"

# Requêtes Traefik 5xx
{job="traefik"} | json | status >= 500

# Auth réussies/échouées dernière heure
{job="acme-app"} |= "login" | json | line_format "{{.level}} {{.user}} {{.result}}"
```

## Ajouter une alerte

1. Éditer `prometheus/alerts/rules.yml`
2. Redéployer : `ansible-playbook playbooks/monitoring.yml --tags alerts`
3. Vérifier dans Prometheus UI : http://monitoring.acme.local:9090/alerts

## Ajouter un dashboard

1. Créer/exporter le JSON depuis Grafana UI
2. Placer dans `monitoring/grafana/dashboards/`
3. Redéployer : `ansible-playbook playbooks/monitoring.yml --tags configure`
