# ACME Corp — Infrastructure Hackathon 2026

Infrastructure d'entreprise sécurisée, observable et reproductible pour ACME Corp (50 salariés).

## Démarrage rapide

```bash
# 1. Cloner le dépôt
git clone <repo> && cd HACKATHON_2026

# 2. Provisionner les VMs (Proxmox requis)
cd terraform
cp terraform.tfvars.example terraform.tfvars   # adapter les valeurs
terraform init && terraform apply

# 3. Configurer toute l'infrastructure
cd ../ansible
cp inventory/group_vars/vault.yml.example inventory/group_vars/vault.yml
ansible-vault edit inventory/group_vars/vault.yml   # renseigner les secrets
ansible-playbook playbooks/site.yml

# 4. Lancer l'application métier
cd ../app && docker compose up -d

# 5. Vérifier l'état
curl -k https://app.acme.local/health
```

---

## Architecture réseau

```mermaid
graph TB
    INTERNET((Internet)):::external

    subgraph WAN["WAN"]
        PFSENSE[pfSense\n192.168.0.1]:::firewall
    end

    subgraph DMZ["DMZ — 192.168.20.0/24"]
        TRAEFIK[Traefik\n192.168.20.10\n:80/:443]:::proxy
        APP[App Flask\n192.168.20.20\n:5000]:::app
        CERTBOT([Certbot / Let's Encrypt]):::cert
    end

    subgraph SERVERS["SERVERS — 192.168.10.0/24"]
        FREEIPA[FreeIPA\n192.168.10.10\n:389/:636/:88]:::identity
        POSTGRES[PostgreSQL\n192.168.10.20\n:5432]:::db
        MONITORING[Prometheus + Grafana\n192.168.10.30\n:9090/:3000]:::monitoring
        LOKI[Loki + Promtail\n192.168.10.40\n:3100]:::logging
        BAREOS[Bareos\n192.168.10.50\n:9101-9103]:::backup
    end

    subgraph LAN["LAN_USERS — 192.168.1.0/24"]
        USERS[Postes utilisateurs]:::users
        ADMIN[Admin]:::admin
    end

    INTERNET -->|HTTPS :443| PFSENSE
    PFSENSE -->|NAT forward| TRAEFIK
    TRAEFIK -->|TLS via| CERTBOT
    TRAEFIK -->|reverse proxy| APP
    APP -->|LDAP :389| FREEIPA
    APP -->|SQL :5432| POSTGRES

    USERS -->|HTTPS via pfSense| TRAEFIK
    ADMIN -->|SSH :22| PFSENSE

    APP -.->|logs Promtail| LOKI
    TRAEFIK -.->|métriques :8080| MONITORING
    FREEIPA -.->|métriques| MONITORING
    POSTGRES -.->|métriques pg_exporter| MONITORING
    LOKI -.->|datasource| MONITORING

    POSTGRES -.->|backup| BAREOS
    APP -.->|backup données| BAREOS

    classDef firewall fill:#e74c3c,color:#fff,stroke:#c0392b
    classDef proxy fill:#3498db,color:#fff,stroke:#2980b9
    classDef app fill:#2ecc71,color:#fff,stroke:#27ae60
    classDef identity fill:#9b59b6,color:#fff,stroke:#8e44ad
    classDef db fill:#f39c12,color:#fff,stroke:#e67e22
    classDef monitoring fill:#1abc9c,color:#fff,stroke:#16a085
    classDef logging fill:#34495e,color:#fff,stroke:#2c3e50
    classDef backup fill:#e67e22,color:#fff,stroke:#d35400
    classDef users fill:#95a5a6,color:#fff,stroke:#7f8c8d
    classDef admin fill:#c0392b,color:#fff,stroke:#96281b
    classDef external fill:#ecf0f1,stroke:#bdc3c7
    classDef cert fill:#27ae60,color:#fff,stroke:#1e8449
```

---

## Flux d'authentification

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant PF as pfSense
    participant TR as Traefik
    participant APP as App Flask
    participant IPA as FreeIPA (LDAP)
    participant PG as PostgreSQL
    participant LK as Loki

    U->>PF: HTTPS :443 → app.acme.local
    PF->>TR: NAT forward :443
    TR->>TR: TLS termination (Let's Encrypt)
    TR->>APP: HTTP :5000
    APP->>IPA: LDAP bind (uid=user,dc=acme,dc=local)
    IPA-->>APP: memberOf → groupes/rôles
    APP->>PG: SELECT / INSERT selon rôle
    PG-->>APP: données
    APP-->>TR: 200 OK + HTML
    TR-->>U: réponse HTTPS chiffrée
    APP-)LK: log structuré (Promtail → Loki)
```

---

## Zones et politique firewall résumée

| Source | Destination | Port | Action |
|--------|-------------|------|--------|
| WAN | DMZ:Traefik | 443/tcp | ALLOW |
| WAN | * | * | DENY |
| DMZ:App | SERVERS:FreeIPA | 389,636/tcp | ALLOW |
| DMZ:App | SERVERS:PostgreSQL | 5432/tcp | ALLOW |
| DMZ:App | SERVERS:Loki | 3100/tcp | ALLOW |
| LAN_USERS | DMZ | 443/tcp | ALLOW |
| LAN_USERS | SERVERS:FreeIPA | 389,636,88/tcp+udp | ALLOW |
| SERVERS | SERVERS | * | ALLOW |
| SERVERS | WAN | 80,443/tcp | ALLOW |

Politique complète : [docs/firewall-policy.md](docs/firewall-policy.md)

---

## Services et accès

| Service | URL | Credentials |
|---------|-----|-------------|
| Application interne | https://app.acme.local | LDAP (FreeIPA) |
| Grafana | https://grafana.acme.local | admin / voir vault |
| FreeIPA WebUI | https://ipa.acme.local | admin / voir vault |
| Traefik dashboard | https://traefik.acme.local | basic auth |
| Bareos WebUI | https://bareos.acme.local | admin / voir vault |

---

## Arborescence

```
HACKATHON_2026/
├── AGENT.md                        # Contexte global agents IA
├── README.md                       # Ce fichier
├── terraform/                      # Provisioning VMs Proxmox
│   ├── AGENT.md
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/vm/ + modules/network/
├── ansible/                        # Configuration services
│   ├── AGENT.md
│   ├── ansible.cfg
│   ├── inventory/hosts.yml + group_vars/
│   ├── playbooks/site.yml + *.yml
│   └── roles/ (freeipa, traefik, postgresql, prometheus, grafana, loki, bareos, certbot)
├── app/                            # Application Flask
│   ├── AGENT.md + README.md
│   ├── docker-compose.yml + Dockerfile
│   └── src/ (app.py, models/, routes/, templates/)
├── monitoring/                     # Prometheus, Grafana, Loki
│   ├── AGENT.md
│   ├── prometheus/ + grafana/ + loki/
└── docs/
    ├── architecture.md
    ├── firewall-policy.md
    └── decisions.md
```

---

## Redéploiement complet (procédure jury — 20 min)

```bash
# Prérequis : Proxmox + terraform.tfvars + vault.yml renseignés

# Étape 1 — VMs (~5 min)
cd terraform && terraform apply -auto-approve

# Étape 2 — Services (~15 min)
cd ../ansible && ansible-playbook playbooks/site.yml

# Étape 3 — Application (~1 min)
cd ../app && docker compose up -d

# Vérification globale
curl -sk https://app.acme.local/health | jq
```

---

## Tests

```bash
# Healthcheck
curl -sk https://app.acme.local/health

# Test de charge K6
k6 run app/tests/k6/smoke.js
k6 run app/tests/k6/load.js

# Test LDAP
ldapsearch -H ldap://192.168.10.10 \
  -D "uid=admin,cn=users,cn=accounts,dc=acme,dc=local" \
  -W -b "dc=acme,dc=local" "(objectClass=posixAccount)"

# Vérifier les métriques Prometheus
curl http://192.168.10.30:9090/api/v1/query?query=up
```

---

## Décisions techniques

Voir [docs/decisions.md](docs/decisions.md).

| Choix | Justification |
|-------|---------------|
| pfSense | Firewall éprouvé, GUI pour démo rapide, XML restore |
| Traefik | Auto-découverte Docker, Certbot intégré, dashboard |
| FreeIPA | LDAP + Kerberos + DNS tout-en-un, UI web incluse |
| Flask | Léger, lisible jury, LDAP3 simple, 0 magie |
| Loki | 10x moins lourd qu'ELK, compatible Grafana natif |
| Bareos | OSS, backup PostgreSQL via bareos-fd, restore CLI |
| Proxmox/Terraform | IaC reproductible, snapshots pour démo restore |
