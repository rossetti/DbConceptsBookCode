-- Creates a login for an AI assistant: a role that can read every table in the
-- book's databases and change none of them. Run it once, in DataGrip or
-- DBeaver, connected to the postgres database as your own user (the one that
-- created dbconcepts). A role belongs to the whole server, so the one login
-- serves dbconcepts, dbconcepts_history, and any other database there.
--
-- Choose your own password in place of the one below, and keep it only in the
-- configuration of the tool that connects as this login. Running the script a
-- second time stops at CREATE ROLE, with "already exists"; to start over, run
-- DROP ROLE dbconcepts_assistant; first.

-- A role that can sign in, with at most five connections at once.
CREATE ROLE dbconcepts_assistant
    LOGIN PASSWORD 'change-this-password'
    CONNECTION LIMIT 5;

-- Read every table and view, in every schema, of every database on the
-- server. pg_read_all_data is a predefined role (PostgreSQL 14 and later). It
-- grants SELECT and nothing else, and it survives a load file, which drops
-- and recreates the schemas and with them any grant on their tables.
GRANT pg_read_all_data TO dbconcepts_assistant;

-- Every transaction of this login begins read-only, so that a statement that
-- changes data is refused before the privileges are even checked.
ALTER ROLE dbconcepts_assistant SET default_transaction_read_only = on;

-- No statement runs longer than 15 seconds, and no transaction is left open
-- and idle for more than a minute.
ALTER ROLE dbconcepts_assistant SET statement_timeout = '15s';
ALTER ROLE dbconcepts_assistant SET idle_in_transaction_session_timeout = '60s';
