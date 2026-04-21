# Décisions techniques et arbitrages — ACME Corp

## Contexte

Contrainte : 48 heures, 4 à 6 étudiants, infrastructure complète, démonstrable.
L'objectif est de livrer une solution cohérente et défendable, pas la plus exhaustive.

---

## Choix d'architecture

### pfSense comme firewall

**Décision** : pfSense plutôt qu'un Linux/iptables custom.

**Raison** : GUI web complète, règles firewall explicites et exportables XML, VLAN simple à configurer, configuration restaurable en 30 secondes pour la démo. Un iptables maison serait plus flexible mais moins lisible et plus risqué à configurer sous contrainte de temps.

**Limite** : pfSense doit être configuré manuellement via GUI (ou API limitée). Le XML de backup est commité dans le dépôt pour la restauration.

---

### Traefik plutôt que Nginx

**Décision** : Traefik v3 comme reverse proxy.

**Raison** : intégration native Certbot/Let's Encrypt (acme.json), auto-découverte Docker via labels, dashboard intégré pour la démo, renouvellement TLS automatique. Nginx nécessiterait une config manuelle des virtualHosts et un cron Certbot séparé.

**Limite** : Traefik est moins connu que Nginx dans certains contextes sécurité.

---

### FreeIPA plutôt qu'OpenLDAP

**Décision** : FreeIPA comme annuaire central.

**Raison** : LDAP + Kerberos + DNS + PKI intégrés en un seul composant, UI web incluse pour la démo, gestion des groupes native, modules Ansible communautaires disponibles. OpenLDAP demande une configuration schema plus complexe.

**Limite** : FreeIPA est lourd (4 Go RAM recommandés), installation lente (~15 min). Sur un hackathon on préfère la robustesse à la légèreté ici.

---

### Flask plutôt que Django ou Node.js

**Décision** : Flask + SQLAlchemy pour l'application métier.

**Raison** : code lisible par le jury en quelques minutes, pas de magie framework, intégration LDAP triviale avec ldap3, structlog JSON natif. Django serait trop verbeux pour une app simple. Node.js ajouterait un langage supplémentaire à maîtriser.

**Limite** : Flask n'est pas aussi structurant que Django, la rigueur de l'organisation est manuelle.

---

### Loki plutôt qu'ELK

**Décision** : Loki + Promtail + Grafana pour la centralisation des logs.

**Raison** : 10× moins de ressources qu'Elasticsearch, intégration native Grafana (même interface que Prometheus), déploiement en un binaire. ELK nécessiterait une VM dédiée avec 8+ Go RAM.

**Limite** : Loki ne fait pas d'indexation plein texte comme Elasticsearch. Les requêtes LogQL sont moins expressives. Acceptable pour un cas d'usage hackathon.

---

### Bareos plutôt que Restic ou Velero

**Décision** : Bareos pour les sauvegardes.

**Raison** : open-source, backup PostgreSQL via bareos-fd nativement, WebUI incluse pour la démo de restauration, planification intégrée, gestion des jobs et des pools.

**Limite** : Bareos est complexe à configurer initialement (Director, Storage, FileDaemon). La configuration est gérée via Ansible pour limiter ce risque.

---

### Proxmox comme hyperviseur (Terraform)

**Décision** : Terraform avec le provider `telmate/proxmox`.

**Raison** : Proxmox est l'hyperviseur standard dans les labos étudiants, le provider Terraform permet un IaC reproductible. Alternative : scripts bash de clonage VM, moins lisible et non idempotent.

**Limite** : Le provider Proxmox est communautaire (non officiel Hashicorp). En cas de problème, repli sur la création manuelle des VMs.

---

## Risques identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Certbot DNS challenge complexe | Moyenne | Moyen | Utiliser HTTP challenge + wildcard self-signed pour démo |
| FreeIPA installation longue | Haute | Faible | Lancer en premier, `args.creates` pour idempotence |
| pfSense non automatisable | Haute | Moyen | Config XML restaurée manuellement, règles documentées |
| Réseau lab non routable WAN | Haute | Moyen | Let's Encrypt remplacé par certificats auto-signés en lab |
| Bareos config complexe | Moyenne | Moyen | Template Ansible pré-testé, job simple PostgreSQL |

---

## Ce qui n'a pas été fait (et pourquoi)

- **MFA / 2FA** : hors scope 48h, FreeIPA le supporte nativement si besoin futur
- **Haute disponibilité** : 1 VM par service suffit pour la démo, HA multiplierait la complexité par 2
- **WAF** : Traefik plugin CrowdSec existe mais non configuré faute de temps
- **SIEM** : Loki + Grafana couvre le minimum requis, SIEM complet hors scope
- **VPN** : pfSense supporte OpenVPN mais non configuré, non demandé explicitement
