# AGENT.md — Ansible / Configuration

## Rôle

Configurer tous les services de l'infrastructure ACME Corp après le provisioning Terraform.
L'ordre d'exécution est géré par `playbooks/site.yml`.

## Inventaire

```
ansible/inventory/
├── hosts.yml                  # Hôtes et groupes
└── group_vars/
    ├── all.yml                # Variables communes (IPs, domaine, ports)
    ├── vault.yml              # Secrets chiffrés (ansible-vault)
    └── vault.yml.example      # Template à copier
```

## Groupes et hôtes

| Groupe | Hôte | IP | OS | VLAN |
|--------|------|----|----|------|
| `identity` | freeipa | 10.20.0.10 | Rocky Linux 9 | 20 |
| `database` | postgresql | 10.20.0.20 | Debian 12 | 20 |
| `monitoring` | prometheus | 10.20.0.40 | Debian 12 | 20 |
| `monitoring` | grafana | 10.20.0.41 | Ubuntu 22.04 | 20 |
| `logging` | loki | 10.20.0.42 | Debian 12 | 20 |
| `backup` | bareos | 10.20.0.50 | Ubuntu 22.04 | 20 |
| `proxy` | traefik | 10.30.0.10 | Debian 12 | 30 |

Groupes logiques : `servers` (identity + database + monitoring + logging + backup), `dmz` (proxy).

## Rôles disponibles

| Rôle | Service | OS cible |
|------|---------|----------|
| `freeipa` | FreeIPA server + DNS + users | Rocky Linux 9 (`dnf`) |
| `postgresql` | PostgreSQL 15 + pg_exporter | Debian 12 (`apt`) |
| `prometheus` | Prometheus + Alertmanager | Debian 12 (binaire) |
| `grafana` | Grafana + datasources | Ubuntu 22.04 (`apt`) |
| `loki` | Loki + Promtail | Debian 12 (binaire) |
| `bareos` | Bareos Director + SD + WebUI | Ubuntu 22.04 (`apt`) |
| `traefik` | Traefik + config dynamique | Debian 12 (Docker) |
| `certbot` | Certificats Let's Encrypt | Debian 12 (via Traefik) |

## Gestion des secrets

```bash
# Créer le vault depuis l'exemple
cp inventory/group_vars/vault.yml.example inventory/group_vars/vault.yml
ansible-vault encrypt inventory/group_vars/vault.yml

# Éditer
ansible-vault edit inventory/group_vars/vault.yml

# Lancer avec vault
ansible-playbook playbooks/site.yml --ask-vault-pass
ansible-playbook playbooks/site.yml --vault-password-file ~/.vault_pass
```

## Tags disponibles

| Tag | Effet |
|-----|-------|
| `install` | Installation des paquets seulement |
| `configure` | Configuration seulement |
| `restart` | Restart des services |
| `users` | Gestion des utilisateurs FreeIPA |
| `backup` | Opérations de sauvegarde |
| `alerts` | Déploiement règles Prometheus |
| `verify` | Post-tasks de vérification |

```bash
# Reconfigurer Traefik uniquement
ansible-playbook playbooks/site.yml --tags configure --limit proxy

# Créer les utilisateurs FreeIPA
ansible-playbook playbooks/freeipa.yml --tags users

# Mettre à jour les alertes Prometheus
ansible-playbook playbooks/monitoring.yml --tags alerts
```

## Commandes utiles

```bash
# Vérifier la connectivité SSH vers tous les hôtes
ansible all -m ping

# Dry-run complet
ansible-playbook playbooks/site.yml --check --diff

# Déploiement complet
ansible-playbook playbooks/site.yml --ask-vault-pass

# Service par service
ansible-playbook playbooks/freeipa.yml
ansible-playbook playbooks/postgresql.yml
ansible-playbook playbooks/loki.yml
ansible-playbook playbooks/monitoring.yml
ansible-playbook playbooks/traefik.yml
ansible-playbook playbooks/backup.yml

# Restart ciblé
ansible-playbook playbooks/monitoring.yml --tags restart --limit prometheus
```

## Dépendances entre rôles

```
freeipa → postgresql → bareos (backup FD)
freeipa → traefik    (LDAP auth middleware)
prometheus → grafana  (datasources)
loki → grafana        (datasource Loki)
```

## Conventions

- Handlers : `restart <service>`, `reload <service>`
- Templates Jinja2 : `<fichier>.j2`
- Defaults : toujours définis dans `defaults/main.yml`
- Boucles : `loop:` (pas `with_items:`)
- Secrets : variables préfixées `vault_` dans `vault.yml`
