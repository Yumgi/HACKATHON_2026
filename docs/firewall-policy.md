# Politique Firewall — ACME Corp

## Zones réseau

| Zone | Réseau | Rôle |
|------|--------|------|
| WAN | IP publique / NAT | Accès Internet entrant |
| LAN_USERS | 192.168.1.0/24 | Postes utilisateurs |
| SERVERS | 192.168.10.0/24 | Services internes |
| DMZ | 192.168.20.0/24 | Services exposés |

## Règles pfSense — WAN → DMZ

| # | Source | Destination | Port | Proto | Action | Description |
|---|--------|-------------|------|-------|--------|-------------|
| 1 | WAN any | 192.168.20.10 (Traefik) | 443 | TCP | ALLOW | HTTPS entrant |
| 2 | WAN any | 192.168.20.10 (Traefik) | 80 | TCP | ALLOW | HTTP → redirect HTTPS |
| 99 | WAN any | any | any | any | DENY | Bloc par défaut WAN |

## Règles pfSense — LAN_USERS → DMZ

| # | Source | Destination | Port | Proto | Action | Description |
|---|--------|-------------|------|-------|--------|-------------|
| 1 | 192.168.1.0/24 | 192.168.20.10 (Traefik) | 443 | TCP | ALLOW | Accès app interne |
| 2 | 192.168.1.0/24 | 192.168.20.10 (Traefik) | 80 | TCP | ALLOW | HTTP → redirect |
| 99 | 192.168.1.0/24 | 192.168.20.0/24 | any | any | DENY | Isolation DMZ |

## Règles pfSense — LAN_USERS → SERVERS

| # | Source | Destination | Port | Proto | Action | Description |
|---|--------|-------------|------|-------|--------|-------------|
| 1 | 192.168.1.0/24 | 192.168.10.10 (FreeIPA) | 389,636 | TCP | ALLOW | LDAP / LDAPS |
| 2 | 192.168.1.0/24 | 192.168.10.10 (FreeIPA) | 88 | TCP+UDP | ALLOW | Kerberos |
| 3 | 192.168.1.0/24 | 192.168.10.10 (FreeIPA) | 443 | TCP | ALLOW | FreeIPA WebUI |
| 4 | 192.168.1.0/24 | 192.168.10.30 (Grafana) | 3000 | TCP | ALLOW | Grafana (admin only) |
| 99 | 192.168.1.0/24 | 192.168.10.0/24 | any | any | DENY | Bloc par défaut |

## Règles pfSense — DMZ → SERVERS

| # | Source | Destination | Port | Proto | Action | Description |
|---|--------|-------------|------|-------|--------|-------------|
| 1 | 192.168.20.20 (App) | 192.168.10.10 (FreeIPA) | 389,636 | TCP | ALLOW | Auth LDAP applicative |
| 2 | 192.168.20.20 (App) | 192.168.10.20 (PostgreSQL) | 5432 | TCP | ALLOW | Base de données |
| 3 | 192.168.20.20 (App) | 192.168.10.40 (Loki) | 3100 | TCP | ALLOW | Envoi logs |
| 4 | 192.168.20.10 (Traefik) | 192.168.10.30 (Grafana) | 3000 | TCP | ALLOW | Proxying Grafana |
| 99 | 192.168.20.0/24 | 192.168.10.0/24 | any | any | DENY | Bloc par défaut |

## Règles pfSense — SERVERS → SERVERS

| # | Source | Destination | Port | Proto | Action | Description |
|---|--------|-------------|------|-------|--------|-------------|
| 1 | 192.168.10.0/24 | 192.168.10.0/24 | any | any | ALLOW | Communication inter-services |

## Règles pfSense — SERVERS → WAN

| # | Source | Destination | Port | Proto | Action | Description |
|---|--------|-------------|------|-------|--------|-------------|
| 1 | 192.168.10.0/24 | any | 80,443 | TCP | ALLOW | Mises à jour, dépôts |
| 2 | 192.168.20.0/24 | any | 80,443 | TCP | ALLOW | Certbot Let's Encrypt |
| 99 | any | any | any | any | DENY | Bloc par défaut sortant |

## Accès SSH administrateur

| Source | Destination | Port | Action | Condition |
|--------|-------------|------|--------|-----------|
| 192.168.1.0/24 (Admin) | Tout hôte | 22 | ALLOW | Via jump host uniquement |
| WAN | Tout hôte | 22 | DENY | Jamais exposé |

## Principe de moindre privilège

1. **WAN** : seul le port 443/80 vers Traefik est ouvert. Tout le reste est bloqué.
2. **DMZ** : les services exposés n'ont accès qu'aux services SERVERS dont ils ont besoin.
3. **LAN_USERS** : les utilisateurs accèdent uniquement à FreeIPA (auth) et Traefik (app).
4. **SERVERS** : communication libre entre services internes, sortie WAN limitée aux mises à jour.
5. **SSH** : accessible uniquement depuis LAN_USERS, jamais depuis WAN.

## Exposition minimale

Services **non exposés** sur WAN :
- PostgreSQL (5432)
- Prometheus (9090)
- Grafana (3000) — accessible uniquement via Traefik avec auth
- Bareos (9101-9103)
- Loki (3100)
- FreeIPA admin (443 accessible depuis LAN uniquement)
