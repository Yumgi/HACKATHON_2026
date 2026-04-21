# ACME Corp — Infrastructure Hackathon 2026

Infrastructure d'entreprise sécurisée, observable et reproductible pour ACME Corp (50 salariés).
Proxmox 8.3.3 · LXC · Terraform · Ansible

## Démarrage rapide

```bash
# 1 — Provisionner les containers LXC
cd terraform
cp terraform.tfvars.example terraform.tfvars   # adapter les valeurs
terraform init && terraform apply

# 2 — Configurer tous les services
cd ../ansible
cp inventory/group_vars/vault.yml.example inventory/group_vars/vault.yml
ansible-vault edit inventory/group_vars/vault.yml
ansible-playbook playbooks/site.yml --ask-vault-pass

# 3 — Vérifier
ansible all -m ping
curl -sk https://grafana.acme.local/api/health
```

---

## Architecture réseau

```mermaid
graph TB
    INTERNET((Internet)):::external

    subgraph WAN["WAN — 10.230.101.0/24"]
        PFSENSE[pfSense\n10.230.101.254\n→ 10.231.254.254]:::firewall
    end

    subgraph DMZ["VLAN 30 — DMZ — 10.30.0.0/24"]
        TRAEFIK[Traefik\n10.30.0.10\n:80 / :443]:::proxy
        CERTBOT([Let's Encrypt\nCertbot]):::cert
    end

    subgraph SERVERS["VLAN 20 — SERVERS — 10.20.0.0/24"]
        FREEIPA[FreeIPA\n10.20.0.10\nLDAP · Kerberos · DNS]:::identity
        POSTGRES[PostgreSQL\n10.20.0.20\n:5432]:::db
        PROMETHEUS[Prometheus\n10.20.0.40\n:9090]:::monitoring
        GRAFANA[Grafana\n10.20.0.41\n:3000]:::monitoring
        LOKI[Loki\n10.20.0.42\n:3100]:::logging
        BAREOS[Bareos\n10.20.0.50\n:9101-9103]:::backup
    end

    subgraph LAN["VLAN 10 — LAN — 10.10.0.0/24"]
        ADMIN[Admin\n10.10.0.10]:::admin
        USERS[Users DHCP\n10.10.0.100-200]:::users
    end

    INTERNET -->|HTTPS :443| PFSENSE
    PFSENSE -->|NAT → VLAN 30| TRAEFIK
    TRAEFIK -->|TLS| CERTBOT
    TRAEFIK -->|proxy → VLAN 20| GRAFANA

    USERS -->|HTTPS via pfSense| TRAEFIK
    USERS -->|LDAP :389| FREEIPA
    ADMIN -->|SSH :22| PFSENSE

    TRAEFIK -.->|métriques :8080| PROMETHEUS
    FREEIPA -.->|node_exporter :9100| PROMETHEUS
    POSTGRES -.->|pg_exporter :9187| PROMETHEUS
    LOKI -.->|datasource| GRAFANA
    PROMETHEUS -.->|datasource| GRAFANA

    POSTGRES -.->|backup FD| BAREOS
    FREEIPA -.->|backup FD| BAREOS

    classDef firewall  fill:#e74c3c,color:#fff,stroke:#c0392b
    classDef proxy     fill:#3498db,color:#fff,stroke:#2980b9
    classDef identity  fill:#9b59b6,color:#fff,stroke:#8e44ad
    classDef db        fill:#f39c12,color:#fff,stroke:#e67e22
    classDef monitoring fill:#1abc9c,color:#fff,stroke:#16a085
    classDef logging   fill:#34495e,color:#fff,stroke:#2c3e50
    classDef backup    fill:#e67e22,color:#fff,stroke:#d35400
    classDef users     fill:#95a5a6,color:#fff,stroke:#7f8c8d
    classDef admin     fill:#c0392b,color:#fff,stroke:#96281b
    classDef external  fill:#ecf0f1,stroke:#bdc3c7
    classDef cert      fill:#27ae60,color:#fff,stroke:#1e8449
```

---

## Containers LXC provisionnés

| CT | Hostname | IP | OS | VLAN | Rôle |
|----|----------|----|----|------|------|
| 101 | ipa | 10.20.0.10 | Rocky Linux 9 | 20 | FreeIPA — LDAP/Kerberos/DNS |
| 102 | pg | 10.20.0.20 | Debian 12 | 20 | PostgreSQL 15 |
| 104 | prometheus | 10.20.0.40 | Debian 12 | 20 | Prometheus + Alertmanager |
| 105 | grafana | 10.20.0.41 | Ubuntu 22.04 | 20 | Grafana |
| 106 | loki | 10.20.0.42 | Debian 12 | 20 | Loki + Promtail |
| 107 | bareos | 10.20.0.50 | Ubuntu 22.04 | 20 | Bareos |
| 201 | traefik | 10.30.0.10 | Debian 12 | 30 | Traefik reverse proxy |

---

## Politique firewall résumée

| Source | Destination | Port | Action |
|--------|-------------|------|--------|
| WAN | VLAN 30 : Traefik | 443/tcp | ALLOW |
| WAN | * | * | DENY |
| VLAN 10 | VLAN 30 : Traefik | 443/tcp | ALLOW |
| VLAN 10 | VLAN 20 : FreeIPA | 389,636,88/tcp+udp | ALLOW |
| VLAN 30 | VLAN 20 : Grafana | 3000/tcp | ALLOW |
| VLAN 20 | VLAN 20 | * | ALLOW |
| VLAN 20 | WAN | 80,443/tcp | ALLOW |

Politique complète : [docs/firewall-policy.md](docs/firewall-policy.md)

---

## Accès aux services

| Service | URL (via Traefik) | Accès direct |
|---------|-------------------|--------------|
| Grafana | https://grafana.acme.local | http://10.20.0.41:3000 |
| FreeIPA WebUI | https://ipa.acme.local | http://10.20.0.10 |
| Traefik dashboard | https://traefik.acme.local | http://10.30.0.10:8080 |
| Prometheus | — interne — | http://10.20.0.40:9090 |
| Alertmanager | — interne — | http://10.20.0.40:9093 |
| Loki | — interne — | http://10.20.0.42:3100 |

---

## Arborescence du dépôt

```
HACKATHON_2026/
├── AGENT.md                        # Contexte global agents IA
├── README.md                       # Ce fichier
├── terraform/                      # Provisioning LXC Proxmox
│   ├── AGENT.md
│   ├── main.tf                     # Provider proxmox
│   ├── variables.tf                # Réseau, templates, credentials
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── freeipa.tf                  # CT 101
│   ├── postgresql.tf               # CT 102
│   ├── prometheus.tf               # CT 104
│   ├── grafana.tf                  # CT 105
│   ├── loki.tf                     # CT 106
│   ├── bareos.tf                   # CT 107
│   └── traefik.tf                  # CT 201
├── ansible/                        # Configuration des services
│   ├── AGENT.md
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.yml
│   │   └── group_vars/all.yml + vault.yml
│   ├── playbooks/site.yml + *.yml
│   └── roles/ (freeipa, postgresql, prometheus, grafana, loki, bareos, traefik, certbot)
├── monitoring/                     # Configs Prometheus, Grafana, Loki
│   ├── AGENT.md
│   ├── prometheus/alerts/rules.yml
│   ├── grafana/dashboards/
│   └── loki/loki-config.yml + promtail-config.yml
├── app/                            # Application métier (à définir)
│   └── AGENT.md
└── docs/
    ├── firewall-policy.md
    └── decisions.md
```

---

## Redéploiement complet (procédure jury)

```bash
# Prérequis : terraform.tfvars + vault.yml renseignés, bridges vmbr2/vmbr3 sur Proxmox

# Étape 1 — Containers LXC (~2 min)
cd terraform && terraform apply -auto-approve

# Étape 2 — Services (~15 min)
cd ../ansible && ansible-playbook playbooks/site.yml --ask-vault-pass

# Vérification
ansible all -m ping
curl -sk https://grafana.acme.local/api/health | jq
curl http://10.20.0.40:9090/api/v1/query?query=up | jq '.data.result[] | {job:.metric.job, up:.value[1]}'
```

---

## Observabilité

```bash
# État des targets Prometheus
curl -s http://10.20.0.40:9090/api/v1/targets | jq '.data.activeTargets[] | {job:.labels.job, health:.health}'

# Requête Loki — erreurs LDAP
logcli query '{job="freeipa"} |= "INVALID_CREDENTIALS"' --addr=http://10.20.0.42:3100
```

---

## Sauvegarde et restauration

```bash
# Déclencher un backup PostgreSQL via bconsole (sur bareos)
echo -e "run job=backup-postgresql yes\nwait\nquit" | bconsole

# Restauration PostgreSQL
pg_restore -U postgres -d acme_app /var/backups/postgresql/acme_app_<date>.dump
```

---

## Décisions techniques — résumé

Voir [docs/decisions.md](docs/decisions.md).

| Choix | Justification |
|-------|---------------|
| LXC plutôt que VMs | Plus léger, démarrage rapide, adapté au lab Proxmox |
| pfSense | Firewall éprouvé, GUI pour démo, restauration XML |
| Traefik | Certbot intégré, dashboard, config dynamique |
| FreeIPA | LDAP + Kerberos + DNS tout-en-un sur Rocky Linux 9 |
| Loki | 10× plus léger qu'ELK, natif Grafana |
| Bareos | OSS, backup PostgreSQL natif, WebUI pour démo |
