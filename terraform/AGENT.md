# AGENT.md — Terraform / Provisioning

## Rôle de ce module

Provisionner les machines virtuelles ACME Corp sur Proxmox via le provider `telmate/proxmox`.
Chaque VM correspond à un service de l'infrastructure.

## Provider

```
telmate/proxmox ~> 2.9
```

## VMs provisionnées

| Ressource Terraform | Hostname | IP | vCPU | RAM | Zone |
|---------------------|----------|----|------|-----|------|
| `acme-pfsense` | pfsense.acme.local | WAN + 3 interfaces | 2 | 4G | WAN/DMZ/SERVERS/LAN |
| `acme-freeipa` | ipa.acme.local | 192.168.10.10 | 2 | 4G | SERVERS |
| `acme-traefik` | traefik.acme.local | 192.168.20.10 | 2 | 2G | DMZ |
| `acme-app` | app.acme.local | 192.168.20.20 | 2 | 2G | DMZ |
| `acme-postgres` | pg.acme.local | 192.168.10.20 | 2 | 4G | SERVERS |
| `acme-monitoring` | monitoring.acme.local | 192.168.10.30 | 2 | 4G | SERVERS |
| `acme-loki` | loki.acme.local | 192.168.10.40 | 2 | 2G | SERVERS |
| `acme-bareos` | bareos.acme.local | 192.168.10.50 | 2 | 2G | SERVERS |

## Convention de nommage

- Toutes les ressources préfixées `acme-`
- Tags Proxmox : `acme`, `<zone>`, `<rôle>`
- VLANs : LAN_USERS=10, SERVERS=20, DMZ=30

## Variables sensibles

Ne jamais committer `terraform.tfvars`. Utiliser un fichier `.tfvars` local ou des variables d'environnement :

```bash
export TF_VAR_proxmox_password="..."
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"
```

## Modules disponibles

- `modules/vm/` — VM générique Proxmox (clone depuis template cloud-init)
- `modules/network/` — Déclaration des bridges/VLANs Proxmox

## Commandes

```bash
terraform init                    # initialiser les providers
terraform plan                    # vérifier les changements
terraform apply                   # appliquer
terraform apply -target=module.freeipa  # appliquer un seul module
terraform destroy                 # supprimer tout (attention)
terraform output                  # voir les IPs générées
```

## Dépendances inter-modules

```
network → vm (tous les VMs dépendent des bridges réseau)
vm.freeipa → vm.app (l'app attend FreeIPA)
vm.postgres → vm.app
```

## Template Proxmox attendu

Le template `ubuntu-22.04-cloud` doit exister sur Proxmox avec :
- Cloud-init activé
- SSH activé
- `qemu-guest-agent` installé
