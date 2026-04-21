# AGENT.md — Application métier Flask (ACME Corp)

## Rôle

Application interne de ticketing léger pour ACME Corp.
Permet aux employés de créer, consulter, modifier et clore des tickets d'assistance.

## Stack technique

- **Runtime** : Python 3.11 + Flask
- **Auth** : LDAP via FreeIPA (ldap3)
- **Base** : PostgreSQL 15 (psycopg2)
- **Logs** : structlog (JSON) → Promtail → Loki
- **Métriques** : prometheus_flask_exporter → Prometheus
- **Conteneur** : Docker + docker-compose

## Rôles applicatifs (mappés sur les groupes FreeIPA)

| Groupe LDAP | Rôle app | Droits |
|-------------|----------|--------|
| `acme-admins` | Admin | CRUD complet, gestion utilisateurs, accès tous tickets |
| `acme-users` | User | Créer/lire/modifier ses propres tickets |
| `acme-readonly` | Viewer | Lecture seule (tous tickets) |

## Endpoints

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| GET | `/health` | Non | Healthcheck (200 OK + JSON) |
| GET | `/metrics` | Non | Métriques Prometheus |
| POST | `/auth/login` | Non | Login LDAP |
| POST | `/auth/logout` | Oui | Déconnexion |
| GET | `/tickets` | Oui | Liste des tickets |
| POST | `/tickets` | User+ | Créer un ticket |
| GET | `/tickets/<id>` | Oui | Détail ticket |
| PUT | `/tickets/<id>` | User+ | Modifier ticket |
| DELETE | `/tickets/<id>` | Admin | Supprimer ticket |
| PATCH | `/tickets/<id>/close` | User+ | Clore ticket |

## Configuration (variables d'environnement)

```env
FLASK_ENV=production
SECRET_KEY=...
DATABASE_URL=postgresql://acme:password@192.168.10.20:5432/acme_app
LDAP_URL=ldap://192.168.10.10
LDAP_BASE_DN=dc=acme,dc=local
LDAP_BIND_DN=uid=svc-app,cn=users,cn=accounts,dc=acme,dc=local
LDAP_BIND_PASSWORD=...
LOG_LEVEL=INFO
LOG_FORMAT=json
```

## Lancer localement (dev)

```bash
cd app
python -m venv .venv && source .venv/bin/activate
pip install -r src/requirements.txt
cp .env.example .env   # adapter
flask --app src/app.py run --debug
```

## Lancer en production (Docker)

```bash
docker compose up -d
docker compose logs -f
```

## Sauvegarde des données

```bash
# Backup manuel
docker compose exec db pg_dump acme_app | gzip > backup_$(date +%Y%m%d).sql.gz

# Restauration
gunzip -c backup_20260421.sql.gz | docker compose exec -T db psql acme_app
```

## Tests

```bash
# Healthcheck
curl http://localhost:5000/health

# K6 smoke test
k6 run tests/k6/smoke.js

# K6 load test
k6 run tests/k6/load.js
```

## Logs applicatifs

Format JSON structuré, incluant :
- `timestamp`, `level`, `user`, `action`, `ip`, `ticket_id`, `result`

Exemples d'actions loguées :
- `login_success`, `login_failure`
- `ticket_create`, `ticket_update`, `ticket_close`, `ticket_delete`
- `unauthorized_access`
