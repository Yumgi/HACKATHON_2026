# AGENT.md — ACME Corp Hackathon 2026

## Contexte du projet

Infrastructure d'entreprise 48h pour ACME Corp (PME 50 salariés).
Équipe : Master 1 SRC / Sécurité, 4 à 6 étudiants.
Hyperviseur : Proxmox 8.3.3 — containers LXC.

## Stack technique

| Composant | Rôle | IP | OS | VLAN |
|-----------|------|----|----|------|
| pfSense | Routeur / Firewall inter-VLAN | WAN 10.230.101.254 | pfSense CE | WAN + 10/20/30 |
| FreeIPA | Annuaire LDAP + Kerberos + DNS | 10.20.0.10 | Rocky Linux 9 | VLAN 20 |
| PostgreSQL | Base de données | 10.20.0.20 | Debian 12 | VLAN 20 |
| Prometheus | Métriques + Alertmanager | 10.20.0.40 | Debian 12 | VLAN 20 |
| Grafana | Dashboards | 10.20.0.41 | Ubuntu 22.04 | VLAN 20 |
| Loki + Promtail | Logs centralisés | 10.20.0.42 | Debian 12 | VLAN 20 |
| Bareos | Sauvegarde | 10.20.0.50 | Ubuntu 22.04 | VLAN 20 |
| Traefik | Reverse proxy HTTPS + TLS | 10.30.0.10 | Debian 12 | VLAN 30 |
| Certbot/Let's Encrypt | Certificats TLS | via Traefik | — | VLAN 30 |
| K6 | Tests de charge | poste local | — | — |

## Plan d'adressage réseau

| VLAN | Nom | Réseau | Passerelle | Usage |
|------|-----|--------|------------|-------|
| — | WAN | 10.230.101.0/24 | 10.231.254.254 | Accès Internet |
| 10 | LAN | 10.10.0.0/24 | 10.10.0.1 | Postes utilisateurs + admin |
| 20 | SERVERS | 10.20.0.0/24 | 10.20.0.1 | Services internes |
| 30 | DMZ | 10.30.0.0/24 | 10.30.0.1 | Services exposés |

## Structure du dépôt

```
HACKATHON_2026/
├── AGENT.md                  ← vous êtes ici
├── README.md                 ← documentation principale + schéma Mermaid
├── terraform/                ← provisioning containers LXC Proxmox
│   ├── AGENT.md
│   ├── main.tf               ← provider proxmox
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── freeipa.tf            ← CT 101
│   ├── postgresql.tf         ← CT 102
│   ├── prometheus.tf         ← CT 104
│   ├── grafana.tf            ← CT 105
│   ├── loki.tf               ← CT 106
│   ├── bareos.tf             ← CT 107
│   └── traefik.tf            ← CT 201
├── ansible/                  ← configuration de tous les services
│   ├── AGENT.md
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       ├── all.yml
│   │       └── vault.yml     ← secrets (ansible-vault)
│   ├── playbooks/
│   │   ├── site.yml          ← playbook principal
│   │   ├── freeipa.yml
│   │   ├── postgresql.yml
│   │   ├── traefik.yml
│   │   ├── monitoring.yml
│   │   ├── loki.yml
│   │   └── backup.yml
│   └── roles/
│       ├── freeipa/
│       ├── traefik/
│       ├── postgresql/
│       ├── prometheus/
│       ├── grafana/
│       ├── loki/
│       ├── bareos/
│       └── certbot/
├── monitoring/               ← configs Prometheus, Grafana, Loki
│   ├── AGENT.md
│   ├── prometheus/
│   │   ├── prometheus.yml    ← (généré via template Ansible)
│   │   └── alerts/rules.yml
│   ├── grafana/dashboards/
│   └── loki/
│       ├── loki-config.yml
│       └── promtail-config.yml
├── app/                      ← application métier (à définir)
│   └── AGENT.md
└── docs/
    ├── firewall-policy.md
    └── decisions.md
```

## Règles pour les agents

- Variables sensibles uniquement dans `ansible/inventory/group_vars/vault.yml` (chiffré ansible-vault)
- Playbooks nommés `<service>.yml`
- Toute nouvelle alerte dans `monitoring/prometheus/alerts/rules.yml`
- Toujours documenter les ports dans `docs/firewall-policy.md`
- Après chaque modification d'IP : vérifier `all.yml`, template prometheus, promtail, dynamic.yml Traefik

## Commandes rapides

```bash
# 1 — Provisionner les containers LXC
cd terraform && terraform init && terraform apply

# 2 — Configurer tous les services
cd ../ansible && ansible-playbook playbooks/site.yml --ask-vault-pass

# 3 — Service individuel
ansible-playbook playbooks/freeipa.yml
ansible-playbook playbooks/monitoring.yml
ansible-playbook playbooks/backup.yml

# Dry-run
ansible-playbook playbooks/site.yml --check --diff
```

## Séquence de démo jury

1. Architecture — VLANs, flux pfSense
2. FreeIPA — utilisateurs, groupes `acme-admins` / `acme-users`
3. Application — (à définir)
4. Traefik — HTTPS, certificats, dashboard
5. Grafana — dashboards infra + logs Loki + alertes Prometheus
6. Bareos — backup déclenché + restauration prouvée
7. Redéploiement : `terraform apply` + `ansible-playbook site.yml`
