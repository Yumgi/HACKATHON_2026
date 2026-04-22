# AGENT.md — Terraform / LXC Proxmox 8

## Structure

Un fichier `.tf` par container. Pas de modules.

```
terraform/
├── main.tf          # provider proxmox uniquement
├── variables.tf     # réseau, templates, credentials
├── outputs.tf       # récapitulatif VMIDs + IPs
│
├── freeipa.tf       # CT 101 — Rocky Linux 9  — 10.20.0.10/24  VLAN 20
├── postgresql.tf    # CT 102 — Debian 12       — 10.20.0.20/24  VLAN 20
├── prometheus.tf    # CT 104 — Debian 12       — 10.20.0.40/24  VLAN 20
├── grafana.tf       # CT 105 — Ubuntu 22.04    — 10.20.0.41/24  VLAN 20
├── loki.tf          # CT 106 — Debian 12       — 10.20.0.42/24  VLAN 20
├── bareos.tf        # CT 107 — Ubuntu 22.04    — 10.20.0.50/24  VLAN 20
│
└── traefik.tf       # CT 201 — Debian 12       — 10.30.0.10/24  VLAN 30
```

## Plan d'adressage

| VLAN | Rôle | Réseau | Passerelle |
|------|------|--------|------------|
| VLAN 10 | LAN Users | 10.10.0.0/24 | 10.10.0.1 (pfSense) |
| VLAN 20 | SERVERS | 10.20.0.0/24 | 10.20.0.1 (pfSense) |
| VLAN 30 | DMZ | 10.30.0.0/24 | 10.30.0.1 (pfSense) |
| WAN | — | 10.229.0.2 (Proxmox) | — |

## Containers et choix d'OS

| Fichier | VMID | IP | OS | Raison |
|---------|------|----|----|--------|
| freeipa.tf | 101 | 10.20.0.10 | Rocky Linux 9 | seul OS officiel FreeIPA upstream |
| postgresql.tf | 102 | 10.20.0.20 | Debian 12 | PGDG stable, empreinte minimale |
| prometheus.tf | 104 | 10.20.0.40 | Debian 12 | binaire Go statique |
| grafana.tf | 105 | 10.20.0.41 | Ubuntu 22.04 | dépôt APT grafana.com → Ubuntu 22.04 |
| loki.tf | 106 | 10.20.0.42 | Debian 12 | binaire Go statique |
| bareos.tf | 107 | 10.20.0.50 | Ubuntu 22.04 | dépôt bareos.org → xUbuntu_22.04 |
| traefik.tf | 201 | 10.30.0.10 | Debian 12 | Docker CE + nesting+keyctl |

## Features LXC

| Container | unprivileged | nesting | keyctl | Raison |
|-----------|-------------|---------|--------|--------|
| freeipa | **false** | true | false | 389-ds + Kerberos → /proc complet |
| postgresql | true | false | false | — |
| prometheus | true | false | false | — |
| grafana | true | false | false | — |
| loki | true | false | false | — |
| bareos | true | false | false | — |
| traefik | true | **true** | **true** | Docker overlay2 dans LXC |

## Dépendances déclarées

```
freeipa → postgresql → bareos
prometheus → grafana
```

## Commandes

```bash
terraform init
terraform plan
terraform apply

# Un seul container
terraform apply -target=proxmox_lxc.prometheus

# Vérifier les IPs
terraform output

# Détruire un container
terraform destroy -target=proxmox_lxc.bareos
```

## Prérequis Proxmox

```bash
# Vérifier les templates disponibles
pveam list local

# Les bridges vmbr2 (VLAN20) et vmbr3 (VLAN30) doivent exister
# avant l'apply — Proxmox UI > Network > Create Linux Bridge
```
