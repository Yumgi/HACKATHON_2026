# AGENT.md — ACME Corp Hackathon 2026

## Contexte du projet

Infrastructure d'entreprise 48h pour ACME Corp (PME 50 salariés).
Équipe : Master 1 SRC / Sécurité, 4 à 6 étudiants.

## Stack technique retenue

| Composant | Rôle | Zone réseau |
|-----------|------|-------------|
| pfSense | Routeur/Firewall | WAN + toutes zones |
| Traefik | Reverse proxy HTTPS | DMZ — 192.168.20.10 |
| FreeIPA | Annuaire LDAP/Kerberos | SERVERS — 192.168.10.10 |
| PostgreSQL | Base de données | SERVERS — 192.168.10.20 |
| Prometheus + Grafana | Supervision | SERVERS — 192.168.10.30 |
| Loki + Promtail | Logs centralisés | SERVERS — 192.168.10.40 |
| Bareos | Sauvegarde | SERVERS — 192.168.10.50 |
| App interne (Flask) | Application métier | DMZ — 192.168.20.20 |
| Certbot/Let's Encrypt | TLS automatique | DMZ (via Traefik) |
| K6 | Tests de charge | poste local / CI |

## Zones réseau

```
LAN_USERS : 192.168.1.0/24   — postes utilisateurs
SERVERS   : 192.168.10.0/24  — services internes
DMZ       : 192.168.20.0/24  — services exposés
WAN       : IP publique / NAT
```

## Structure du dépôt

```
HACKATHON_2026/
├── AGENT.md                  ← vous êtes ici
├── README.md                 ← documentation principale + schéma Mermaid
├── terraform/                ← provisioning VMs Proxmox
│   ├── AGENT.md
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vm/
│       └── network/
├── ansible/                  ← configuration de tous les services
│   ├── AGENT.md
│   ├── ansible.cfg
│   ├── inventory/
│   ├── playbooks/
│   └── roles/
├── app/                      ← application métier Flask
│   ├── AGENT.md
│   ├── README.md
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── src/
├── monitoring/               ← Prometheus, Grafana, Loki
│   ├── AGENT.md
│   ├── prometheus/
│   ├── grafana/
│   └── loki/
└── docs/
    ├── architecture.md
    ├── firewall-policy.md
    └── decisions.md
```

## Règles de travail pour les agents

- Toujours préfixer les ressources Terraform par `acme-`
- Variables sensibles dans `ansible/inventory/group_vars/vault.yml` (ansible-vault)
- Nommage des playbooks : `<service>.yml` (ex: `freeipa.yml`)
- Nommage des rôles Ansible : snake_case (ex: `free_ipa`, `bareos_server`)
- Chaque rôle Ansible doit avoir : `tasks/main.yml`, `defaults/main.yml`, `handlers/main.yml`, `templates/`
- Toujours documenter les ports ouverts dans `docs/firewall-policy.md`
- Toute nouvelle alerte Prometheus dans `monitoring/prometheus/alerts/rules.yml`
- Tests K6 dans `app/tests/k6/`

## Commandes rapides

```bash
# Provisionner les VMs
cd terraform && terraform init && terraform apply

# Déployer toute l'infra
cd ansible && ansible-playbook playbooks/site.yml

# Déployer un service spécifique
ansible-playbook playbooks/freeipa.yml
ansible-playbook playbooks/monitoring.yml

# Lancer l'application
cd app && docker compose up -d

# Test de charge
k6 run app/tests/k6/smoke.js
```

## Séquence de démo jury

1. Architecture + zones réseau (pfSense)
2. FreeIPA : utilisateurs, groupes, rôles
3. Application : CRUD, auth LDAP, healthcheck
4. Traefik + HTTPS (Certbot)
5. Grafana dashboard + Loki logs + alertes Prometheus
6. Bareos : backup déclenché + restauration prouvée
7. Redéploiement en 1 commande
