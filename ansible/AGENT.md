# AGENT.md — Ansible / Configuration

## Rôle de ce module

Configurer tous les services de l'infrastructure ACME Corp après le provisioning Terraform.
L'ordre d'exécution est géré par `playbooks/site.yml`.

## Inventaire

```
ansible/inventory/
├── hosts.yml          # Hôtes et groupes
└── group_vars/
    ├── all.yml        # Variables communes (domaine, DNS, etc.)
    ├── servers.yml    # Variables spécifiques SERVERS zone
    └── vault.yml      # Secrets chiffrés (ansible-vault encrypt)
```

## Groupes d'hôtes

| Groupe | Hôtes | Zone |
|--------|-------|------|
| `identity` | ipa.acme.local | SERVERS |
| `database` | pg.acme.local | SERVERS |
| `monitoring` | monitoring.acme.local | SERVERS |
| `logging` | loki.acme.local | SERVERS |
| `backup` | bareos.acme.local | SERVERS |
| `proxy` | traefik.acme.local | DMZ |
| `app` | app.acme.local | DMZ |

## Rôles disponibles

| Rôle | Service | Description |
|------|---------|-------------|
| `freeipa` | FreeIPA | Installation + bootstrap domain + users |
| `traefik` | Traefik | Reverse proxy + TLS + middlewares |
| `postgresql` | PostgreSQL | Instance + users + backup script |
| `prometheus` | Prometheus | Scrape config + alertmanager |
| `grafana` | Grafana | Dashboards + datasources (Prometheus + Loki) |
| `loki` | Loki + Promtail | Agrégation logs |
| `bareos` | Bareos | Director + Storage + FD + WebUI |
| `certbot` | Certbot | Certificats Let's Encrypt DNS challenge |

## Convention de nommage

- Handlers : `restart <service>`, `reload <service>`
- Templates : `<fichier>.j2`
- Variables defaults : toujours définies dans `defaults/main.yml`
- Boucles : préférer `loop:` à `with_items:`
- Vault : préfixer les variables sensibles par `vault_`

## Gestion des secrets

```bash
# Chiffrer le vault
ansible-vault encrypt inventory/group_vars/vault.yml

# Éditer
ansible-vault edit inventory/group_vars/vault.yml

# Lancer avec vault
ansible-playbook playbooks/site.yml --ask-vault-pass
# ou
ansible-playbook playbooks/site.yml --vault-password-file ~/.vault_pass
```

## Tags disponibles

| Tag | Effet |
|-----|-------|
| `install` | Installation des paquets seulement |
| `configure` | Configuration seulement |
| `restart` | Restart des services |
| `users` | Gestion des utilisateurs |
| `backup` | Opérations de sauvegarde |

```bash
# Exemple : reconfigurer uniquement Traefik
ansible-playbook playbooks/site.yml --tags configure --limit proxy

# Créer les utilisateurs FreeIPA
ansible-playbook playbooks/freeipa.yml --tags users
```

## Commandes utiles

```bash
# Vérifier la connectivité
ansible all -m ping

# Dry-run
ansible-playbook playbooks/site.yml --check --diff

# Déploiement complet
ansible-playbook playbooks/site.yml

# Service spécifique
ansible-playbook playbooks/monitoring.yml
ansible-playbook playbooks/backup.yml

# Forcer restart
ansible-playbook playbooks/site.yml --tags restart --limit monitoring
```

## Dépendances entre rôles

```
freeipa → postgresql → app
freeipa → traefik (LDAP auth middleware)
monitoring + loki → grafana (datasources)
postgresql → bareos (backup FD)
app → bareos (backup FD)
```
