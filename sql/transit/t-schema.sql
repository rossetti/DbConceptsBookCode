-- Millbrook Transit: the tables of a small transit agency's monitoring
-- database, adapted from the Transportation Research Board study that the
-- book's chapter 5 exercises follow (@sec-classmodeling-exercises). Unlike the
-- rest of the book's database, it does not belong to HG Industries; it is a
-- second setting for query exercises.
--
-- Running this script deletes and recreates the transit schema. Load the rows
-- with t-data.sql afterward; scripts/build-transit-db.sh does both.

DROP SCHEMA IF EXISTS transit CASCADE;
CREATE SCHEMA transit;

-- The network: routes, points, and the ordered segments of each route.
CREATE TABLE transit.route (
    route_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    route_number INTEGER NOT NULL UNIQUE,
    name VARCHAR(40) NOT NULL,
    color VARCHAR(10) NOT NULL,
    distance_miles NUMERIC(5, 2) NOT NULL
        CHECK (distance_miles > 0)
);

CREATE TABLE transit.point (
    point_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    point_code VARCHAR(6) NOT NULL UNIQUE,
    name VARCHAR(40) NOT NULL,
    latitude NUMERIC(8, 5) NOT NULL,
    longitude NUMERIC(8, 5) NOT NULL
);

-- A generalization mapped to a table for each class: every access point is a
-- point, and every scheduled point an access point.
CREATE TABLE transit.access_point (
    point_fk INTEGER PRIMARY KEY
        REFERENCES transit.point ON DELETE CASCADE,
    block_location VARCHAR(10) NOT NULL
        CHECK (block_location IN
               ('midblock', 'near side', 'far side', 'off street')),
    waiting_capacity INTEGER NOT NULL CHECK (waiting_capacity >= 0),
    bench_count INTEGER NOT NULL CHECK (bench_count >= 0),
    shelter BOOLEAN NOT NULL
);

CREATE TABLE transit.scheduled_point (
    access_point_fk INTEGER PRIMARY KEY
        REFERENCES transit.access_point ON DELETE CASCADE,
    timetable_posted BOOLEAN NOT NULL
);

CREATE TABLE transit.segment (
    segment_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    route_fk INTEGER NOT NULL
        REFERENCES transit.route ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL CHECK (sequence_number > 0),
    start_point_fk INTEGER NOT NULL REFERENCES transit.point,
    end_point_fk INTEGER NOT NULL REFERENCES transit.point,
    length_miles NUMERIC(4, 2) NOT NULL CHECK (length_miles > 0),
    UNIQUE (route_fk, sequence_number),
    CHECK (start_point_fk <> end_point_fk)
);

-- Schedules: a schedule runs a route on some days of the week, departing the
-- first point every headway_minutes from first_departure to last_departure;
-- its lines give the minutes from departure to each scheduled point.
CREATE TABLE transit.day_of_week (
    day_of_week_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    day_name VARCHAR(9) NOT NULL UNIQUE,
    iso_day INTEGER NOT NULL UNIQUE CHECK (iso_day BETWEEN 1 AND 7)
);

CREATE TABLE transit.schedule (
    schedule_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    route_fk INTEGER NOT NULL
        REFERENCES transit.route ON DELETE CASCADE,
    name VARCHAR(20) NOT NULL,
    first_departure TIME NOT NULL,
    last_departure TIME NOT NULL,
    headway_minutes INTEGER NOT NULL CHECK (headway_minutes > 0),
    last_updated DATE NOT NULL,
    UNIQUE (route_fk, name),
    CHECK (last_departure >= first_departure)
);

CREATE TABLE transit.schedule_day (
    schedule_day_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    schedule_fk INTEGER NOT NULL
        REFERENCES transit.schedule ON DELETE CASCADE,
    day_of_week_fk INTEGER NOT NULL REFERENCES transit.day_of_week,
    UNIQUE (schedule_fk, day_of_week_fk)
);

CREATE TABLE transit.schedule_line (
    schedule_line_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    schedule_fk INTEGER NOT NULL
        REFERENCES transit.schedule ON DELETE CASCADE,
    line_number INTEGER NOT NULL CHECK (line_number > 0),
    scheduled_point_fk INTEGER NOT NULL
        REFERENCES transit.scheduled_point,
    minutes_after_departure INTEGER NOT NULL
        CHECK (minutes_after_departure >= 0),
    UNIQUE (schedule_fk, line_number)
);

-- Operations: vehicles, drivers, and the assignment of a driver to a vehicle
-- on a route for a shift.
CREATE TABLE transit.vehicle (
    vehicle_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_number VARCHAR(6) NOT NULL UNIQUE,
    model_year INTEGER NOT NULL,
    seating_capacity INTEGER NOT NULL CHECK (seating_capacity > 0)
);

CREATE TABLE transit.driver (
    driver_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_number VARCHAR(6) NOT NULL UNIQUE,
    name VARCHAR(40) NOT NULL,
    hired_on DATE NOT NULL
);

CREATE TABLE transit.assignment (
    assignment_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    route_fk INTEGER NOT NULL REFERENCES transit.route,
    vehicle_fk INTEGER NOT NULL REFERENCES transit.vehicle,
    driver_fk INTEGER NOT NULL REFERENCES transit.driver,
    starts_at TIMESTAMP NOT NULL,
    ends_at TIMESTAMP NOT NULL,
    CHECK (ends_at > starts_at)
);

-- The record of service: each run of a route (a route traversal), and each
-- point the bus reached on it, with the passengers boarding and alighting.
CREATE TABLE transit.route_traversal (
    route_traversal_pk INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    assignment_fk INTEGER NOT NULL REFERENCES transit.assignment,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP NOT NULL,
    UNIQUE (assignment_fk, started_at),
    CHECK (ended_at > started_at)
);

CREATE TABLE transit.point_traversal (
    point_traversal_pk INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    route_traversal_fk INTEGER NOT NULL
        REFERENCES transit.route_traversal ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL CHECK (sequence_number > 0),
    point_fk INTEGER NOT NULL REFERENCES transit.point,
    arrived_at TIMESTAMP NOT NULL,
    departed_at TIMESTAMP NOT NULL,
    boardings INTEGER NOT NULL CHECK (boardings >= 0),
    alightings INTEGER NOT NULL CHECK (alightings >= 0),
    UNIQUE (route_traversal_fk, sequence_number),
    CHECK (departed_at >= arrived_at)
);

-- Riders, their accounts and smart cards, and the trips made with the cards.
CREATE TABLE transit.mailing_address (
    mailing_address_pk INTEGER GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,
    street VARCHAR(60) NOT NULL,
    city VARCHAR(40) NOT NULL,
    state CHAR(2) NOT NULL,
    zip_code CHAR(5) NOT NULL
);

CREATE TABLE transit.person (
    person_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    rider_category VARCHAR(8) NOT NULL
        CHECK (rider_category IN ('standard', 'student', 'senior')),
    mailing_address_fk INTEGER REFERENCES transit.mailing_address
        ON DELETE SET NULL
);

CREATE TABLE transit.account (
    account_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_number VARCHAR(8) NOT NULL UNIQUE,
    holder_fk INTEGER NOT NULL REFERENCES transit.person,
    opened_on DATE NOT NULL
);

-- A generalization mapped to one table: card_kind says which kind a card is,
-- and the check ties each kind to its own column.
CREATE TABLE transit.smart_card (
    smart_card_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    card_number VARCHAR(10) NOT NULL UNIQUE,
    issued_on DATE NOT NULL,
    card_kind VARCHAR(6) NOT NULL
        CHECK (card_kind IN ('debit', 'credit')),
    balance NUMERIC(7, 2),
    account_fk INTEGER REFERENCES transit.account,
    person_fk INTEGER REFERENCES transit.person,
    CHECK ((card_kind = 'debit'
            AND balance IS NOT NULL AND account_fk IS NULL)
        OR (card_kind = 'credit'
            AND account_fk IS NOT NULL AND balance IS NULL))
);

CREATE TABLE transit.trip (
    trip_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    smart_card_fk INTEGER NOT NULL REFERENCES transit.smart_card,
    boarding_fk INTEGER NOT NULL REFERENCES transit.point_traversal,
    alighting_fk INTEGER NOT NULL REFERENCES transit.point_traversal,
    fare NUMERIC(5, 2) NOT NULL CHECK (fare >= 0),
    CHECK (boarding_fk <> alighting_fk)
);

CREATE TABLE transit.payment (
    payment_pk INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_fk INTEGER NOT NULL REFERENCES transit.account,
    paid_on DATE NOT NULL,
    amount NUMERIC(8, 2) NOT NULL CHECK (amount > 0),
    payment_type VARCHAR(6) NOT NULL
        CHECK (payment_type IN ('cash', 'check', 'charge'))
);
