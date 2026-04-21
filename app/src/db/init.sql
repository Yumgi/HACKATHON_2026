-- Initialisation de la base ACME Corp
-- Exécuté automatiquement au premier démarrage du conteneur PostgreSQL

CREATE TABLE IF NOT EXISTS tickets (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    status      VARCHAR(20)  NOT NULL DEFAULT 'open',
    priority    VARCHAR(10)  NOT NULL DEFAULT 'medium',
    created_by  VARCHAR(100) NOT NULL,
    assigned_to VARCHAR(100),
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    closed_at   TIMESTAMP
);

-- Données de démonstration
INSERT INTO tickets (title, description, status, priority, created_by) VALUES
    ('Problème imprimante RDC', 'L''imprimante du rez-de-chaussée ne répond plus.', 'open', 'low', 'bob'),
    ('Accès VPN refusé', 'Impossible de se connecter au VPN depuis hier soir.', 'open', 'high', 'carol'),
    ('Mise à jour logiciel comptabilité', 'La version 3.2 est disponible, prévoir la mise à jour.', 'in_progress', 'medium', 'alice');
