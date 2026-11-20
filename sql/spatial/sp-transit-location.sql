-- Millbrook Transit's stops as locations: installs PostGIS in the database and
-- gives transit.point a location column, for the book's appendix on spatial
-- data.
--
-- Run it in dbconcepts_transit, after t-schema.sql and t-data.sql. It needs
-- PostGIS installed with the server (Postgres.app includes it), and a user
-- allowed to create an extension: the user the PostgreSQL installation made
-- for you is. Running it twice changes nothing.
--
-- t-schema.sql drops and recreates the transit schema, so reloading Millbrook
-- removes the column. Run this script again afterward.

CREATE EXTENSION IF NOT EXISTS postgis;

-- The location is computed from latitude and longitude, so the three cannot
-- disagree: an UPDATE of either coordinate changes the location. ST_MakePoint
-- takes the longitude first. SRID 4326 says the numbers are GPS latitude and
-- longitude, and geography measures distance on the Earth, in meters.
ALTER TABLE transit.point
    ADD COLUMN IF NOT EXISTS location geography(Point, 4326)
        GENERATED ALWAYS AS (
            ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
        ) STORED;
