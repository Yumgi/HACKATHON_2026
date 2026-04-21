# AGENT.md — Application métier

## Statut

**Application non déployée.** Ce répertoire contient le code de l'ancienne application Flask (ticketing).
L'application métier définitive est à choisir et à intégrer dans l'infrastructure.

## Contraintes du cahier des charges (hackathon)

L'application doit :
- Répondre à un besoin interne crédible (ticketing, wiki, intranet, portail RH, etc.)
- Comporter une authentification LDAP (FreeIPA — `dc=acme,dc=local`)
- Avoir au moins deux rôles avec droits différents (groupes FreeIPA : `acme-admins`, `acme-users`)
- Utiliser une persistance réelle (PostgreSQL 15 — `10.20.0.20:5432`)
- CRUD complet sur une entité métier
- Logs structurés (JSON) exploitables par Promtail → Loki
- Endpoint `/health` (healthcheck)
- Exposée via Traefik (`10.30.0.10`) en HTTPS

## Intégration dans l'infra existante

| Besoin app | Service | IP |
|-----------|---------|-----|
| Authentification | FreeIPA (LDAP) | 10.20.0.10:389 |
| Base de données | PostgreSQL | 10.20.0.20:5432 |
| Logs | Loki (via Promtail) | 10.20.0.42:3100 |
| Métriques | Prometheus | 10.20.0.40:9090 |
| Exposition HTTPS | Traefik | 10.30.0.10:443 |

## Pour déployer une application

1. Ajouter le container dans `terraform/app.tf` (Debian 12 ou Ubuntu 22.04, VLAN 20)
2. Ajouter l'hôte dans `ansible/inventory/hosts.yml` (groupe `app`)
3. Créer le playbook `ansible/playbooks/app.yml`
4. Ajouter la route dans `ansible/roles/traefik/templates/dynamic.yml.j2`
5. Ajouter le scrape dans `ansible/roles/prometheus/templates/prometheus.yml.j2`
6. Ajouter la source de logs dans `monitoring/loki/promtail-config.yml`
7. Ajouter le client Bareos dans `ansible/playbooks/bareos.yml`
