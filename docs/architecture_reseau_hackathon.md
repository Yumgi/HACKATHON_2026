# 🌐 Architecture Réseau --- Hackathon 2026

## 📡 WAN

  -------------------------------------------------------------------------
  Machine        IP                  Rôle
  -------------- ------------------- --------------------------------------
  pfSense WAN    10.230.101.254/24   Accès vers GW global (10.231.254.254)

  -------------------------------------------------------------------------

------------------------------------------------------------------------

## 🖧 VLAN 10 --- LAN (Users)

  Machine        IP                  Rôle
  -------------- ------------------- ----------------------
  pfSense LAN    10.10.0.1           Passerelle
  Poste Admin    10.10.0.10          Accès SSH / RDP
  Users (DHCP)   10.10.0.100 → 200   Clients utilisateurs

------------------------------------------------------------------------

## 🖥️ VLAN 20 --- SERVERS

  Machine           IP           Rôle
  ----------------- ------------ --------------------
  pfSense SERVERS   10.20.0.1    Passerelle
  FreeIPA           10.20.0.10   LDAP / DNS
  PostgreSQL        10.20.0.20   Base de données
  GLPI              10.20.0.30   ITSM
  Prometheus        10.20.0.40   Collecte métriques
  Grafana           10.20.0.41   Visualisation
  Loki              10.20.0.42   Logs centralisés
  Bareos            10.20.0.50   Sauvegardes

------------------------------------------------------------------------

## 🌍 VLAN 30 --- DMZ

  Machine       IP           Rôle
  ------------- ------------ ---------------------
  pfSense DMZ   10.30.0.1    Passerelle
  Traefik       10.30.0.10   Reverse Proxy HTTPS

------------------------------------------------------------------------

## 🔐 Logique réseau

-   Segmentation stricte par VLAN (10 / 20 / 30)
-   Accès utilisateur → DMZ uniquement (HTTPS)
-   Accès Admin → SERVERS (SSH / RDP)
-   DMZ → SERVERS limité (Traefik → GLPI)
-   SERVERS → DB restreint (GLPI → PostgreSQL)
-   Politique globale : **deny by default**
