-- ============================================================
-- Vägvis — schéma alertes communautaires (version corrigée)
-- Corrige : (1) latitude/longitude absentes de la réponse RPC
--           (2) pas de suivi des votes par utilisateur
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE alert_type AS ENUM (
  'ticket_inspector',
  'delays_weather',
  'crowded_train',
  'bike_space_full',
  'elevator_broken',
  'ice_hazard'          -- ajouté : verglas piste cyclable (utilisé dans les maquettes)
);

CREATE TABLE alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,                              -- nullable : signalement anonyme possible
  alert_type alert_type NOT NULL,
  message TEXT,
  line_number VARCHAR(10),
  stop_area_name VARCHAR(100),
  location GEOGRAPHY(Point, 4326) NOT NULL,
  upvotes INT DEFAULT 1,
  downvotes INT DEFAULT 0,                   -- ajouté : nécessaire pour "Inte längre aktuellt"
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '45 minutes')
);

CREATE INDEX idx_alerts_location ON alerts USING GIST (location);

-- ------------------------------------------------------------
-- Table de suivi des votes : un utilisateur = un vote par alerte
-- Sans ça, rien n'empêche 50 votes du même compte sur une alerte.
-- ------------------------------------------------------------
CREATE TABLE alert_votes (
  alert_id UUID NOT NULL REFERENCES alerts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  vote_value SMALLINT NOT NULL CHECK (vote_value IN (1, -1)),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (alert_id, user_id)
);

-- ------------------------------------------------------------
-- Fonction de recherche par proximité — CORRIGÉE
-- Extrait explicitement latitude/longitude en colonnes,
-- au lieu de renvoyer la colonne `location` brute que le
-- modèle Flutter ne sait pas parser.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_nearby_alerts(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_meters INT DEFAULT 3000
)
RETURNS TABLE (
  id UUID,
  alert_type alert_type,
  message TEXT,
  line_number VARCHAR(10),
  stop_area_name VARCHAR(100),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  upvotes INT,
  downvotes INT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.alert_type,
    a.message,
    a.line_number,
    a.stop_area_name,
    ST_Y(a.location::geometry) AS latitude,
    ST_X(a.location::geometry) AS longitude,
    a.upvotes,
    a.downvotes,
    a.created_at
  FROM alerts a
  WHERE ST_DWithin(
    a.location,
    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
    radius_meters
  )
  AND a.expires_at > NOW()
  ORDER BY a.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- Fonction de vote — un seul vote par utilisateur et par alerte,
-- upsert pour permettre de changer d'avis (confirmer -> annuler).
-- Chaque vote positif étend la durée de vie de +15 min (logique Waze).
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION vote_alert(
  p_alert_id UUID,
  p_user_id UUID,
  p_vote_value SMALLINT
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO alert_votes (alert_id, user_id, vote_value)
  VALUES (p_alert_id, p_user_id, p_vote_value)
  ON CONFLICT (alert_id, user_id)
  DO UPDATE SET vote_value = EXCLUDED.vote_value, created_at = NOW();

  UPDATE alerts SET
    upvotes = (SELECT COUNT(*) FROM alert_votes WHERE alert_id = p_alert_id AND vote_value = 1) + 1,
    downvotes = (SELECT COUNT(*) FROM alert_votes WHERE alert_id = p_alert_id AND vote_value = -1),
    expires_at = CASE WHEN p_vote_value = 1 THEN expires_at + INTERVAL '15 minutes' ELSE expires_at END
  WHERE id = p_alert_id;
END;
$$ LANGUAGE plpgsql;
