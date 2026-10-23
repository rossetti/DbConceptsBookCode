-- HG Industries: remove every schema of the book's database, so the stage
-- scripts can be run again from the beginning.
--
-- This deletes all tables and rows in the schemas below. It does not touch
-- any other schema.
DROP SCHEMA IF EXISTS sales CASCADE;
DROP SCHEMA IF EXISTS quality CASCADE;
DROP SCHEMA IF EXISTS production CASCADE;
DROP SCHEMA IF EXISTS distribution CASCADE;
