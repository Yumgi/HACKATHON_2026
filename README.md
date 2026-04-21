# HACKATHON_2026


## Bareos

Bareos est une solution de sauvegarde open source (AGPLv3) conçue pour les environnements DevOps grâce à son architecture modulaire et client-serveur.  Elle permet de préserver, archiver et récupérer des données sur tous les systèmes d'exploitation majeurs, en communiquant de manière sécurisée via le réseau. 


Pour l'intégration DevOps, Bareos offre des outils d'automatisation et une API, notamment via bconsole (interface en ligne de commande) et bareos-webui (interface web).  Il supporte également des plugins Python et une API JSON-RPC, permettant une gestion programmatique des sauvegardes et des restaurations, essentielle pour les pipelines CI/CD et l'infrastructure as code. 


Dans notre infrastructure, Bareos est utilisé pour garantir la résilience des services critiques et assurer la récupération rapide en cas d’incident.

## Architecture Bareos

Bareos repose sur trois composants principaux :

* Bareos Director : Le chef d'orchestre responsable de la planification, de l'initialisation des travaux de sauvegarde et de la gestion des fichiers à sauvegarder. 
* Storage Daemons (bareos-sd) : Les démons situés sur les serveurs de stockage qui écrivent les données sur les médias physiques (disques, bandes, etc.). 
* File Daemons (bareos-fd) : Les clients installés sur les machines à sauvegarder, qui envoient les données aux démons de stockage après authentification. 


## Intégration dans notre infrastructure

Bareos est déployé dans le VLAN SERVERS avec l’adresse suivante :

Bareos : à définir


Les flux sont autorisés uniquement entre Bareos et les machines sauvegardées, conformément à notre politique de sécurité.

## Données sauvegardées

Les éléments suivants sont sauvegardés :

* Base de données PostgreSQL (GLPI)
* Configuration FreeIPA
* Volumes Docker
* Fichiers système critiques
* Stratégie de sauvegarde
* Sauvegarde complète : 1 fois par jour
* Sauvegarde incrémentale : toutes les 6 heures
* Rétention : 7 jours
* Procédure de restauration

La restauration est effectuée via l’outil bconsole :

* Sélection du job de sauvegarde
* Choix des fichiers à restaurer
* Lancement de la restauration vers la machine cible
* Preuve de fonctionnement

Une restauration complète de la base PostgreSQL a été réalisée avec succès :

* Suppression volontaire de la base
* Restauration via Bareos
* Redémarrage du service
* Validation du bon fonctionnement de l’application

## Justification technique

Le choix de Bareos permet :

* Gestion centralisée des sauvegardes
* Solution scalable adaptée à une PME
* Automatisation possible via API et scripts
* Séparation claire des rôles (sécurité et maintenabilité)

## Limites
* Mise en place plus complexe que des solutions simples (rsync, restic)
* Nécessite une configuration rigoureuse pour éviter les erreurs

Cependant, ce choix est justifié par notre volonté de proposer une solution professionnelle et évolutive.
