-- Confirms that DataGrip or DBeaver is connected to the server, and to which
-- database, as which user. Open it in either tool and run it against the
-- connection you configured. From a terminal, psql runs it too:
--
--   psql -d dbconcepts -f sql/setup/check-connection.sql
SELECT version();
SELECT current_database(), current_user;
