-- Tables for four data files of Anthony DeBarros's Practical SQL, 2nd edition
-- (github.com/anthonydb/practical-sql-2, MIT license, which covers its data).
-- The table and column names are the upstream ones, so the book's own
-- documentation applies; the definitions are written for this loader.
-- load-public.sh creates these tables and copies the files into them
-- (@sec-appsampledbs-public).

-- County population estimates, U.S. Census Bureau, 2018 and 2019.
CREATE TABLE us_counties_pop_est_2019 (
    state_fips TEXT NOT NULL,
    county_fips TEXT NOT NULL,
    region SMALLINT,
    state_name TEXT,
    county_name TEXT,
    area_land BIGINT,
    area_water BIGINT,
    internal_point_lat NUMERIC(10, 7),
    internal_point_lon NUMERIC(10, 7),
    pop_est_2018 INTEGER,
    pop_est_2019 INTEGER,
    births_2019 INTEGER,
    deaths_2019 INTEGER,
    international_migr_2019 INTEGER,
    domestic_migr_2019 INTEGER,
    residual_2019 INTEGER,
    PRIMARY KEY (state_fips, county_fips)
);

-- Meat, poultry, and egg establishments inspected by the U.S. Department of
-- Agriculture, as published; the file has the inconsistencies a real
-- directory has, which is its value for practice in cleaning data.
CREATE TABLE meat_poultry_egg_establishments (
    establishment_number TEXT PRIMARY KEY,
    company TEXT,
    street TEXT,
    city TEXT,
    st TEXT,
    zip TEXT,
    phone TEXT,
    grant_date DATE,
    activities TEXT,
    dbas TEXT
);

-- Monthly U.S. exports of citrus and soybeans, in dollars.
CREATE TABLE us_exports (
    year SMALLINT,
    month SMALLINT,
    citrus_export_value BIGINT,
    soybeans_export_value BIGINT
);

-- Daily high and low temperatures at three weather stations.
CREATE TABLE temperature_readings (
    station_name TEXT,
    observation_date DATE,
    max_temp INTEGER,
    min_temp INTEGER,
    PRIMARY KEY (station_name, observation_date)
);
