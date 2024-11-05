-- Create keyspace
CREATE KEYSPACE IF NOT EXISTS apollo
WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };

--USE apollo;

CREATE TABLE IF NOT EXISTS apollo.org (
    name TEXT PRIMARY KEY,
    owner TEXT,
    members SET<TEXT>,
    permissions SET<TEXT>,
    created_at DATE,
    updated_at DATE
)
    WITH bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'ALL'};

CREATE TABLE IF NOT EXISTS apollo.permission (
    id UUID PRIMARY KEY,
    name TEXT
);

CREATE TABLE IF NOT EXISTS apollo.user (
    name TEXT,
    surname TEXT,
    email TEXT,
    username TEXT,
    created_at DATE,
    updated_at DATE,
    PRIMARY KEY (username)
);
CREATE INDEX IF NOT EXISTS ON apollo.user (email);
--CREATE INDEX email_user_idx ON apollo.user ({"pk":["username"],"ck":["email"]});

CREATE MATERIALIZED VIEW apollo.user_by_email AS
    SELECT * FROM apollo.user
    WHERE username IS NOT NULL AND email IS NOT NULL
    PRIMARY KEY (email, username);

INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'config.get') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'config.put') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'org.namespace.add') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'org.namespace.get') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'namespace.delete') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'namespace.putconfig') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'namespace.put') IF NOT EXISTS; -- za bilo kakve izmene ns i dodelu resursa
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'namespace.app.add') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'app.delete') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'app.put') IF NOT EXISTS; -- dodela resursa app
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'node.get') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'node.put') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'node.label.put') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'node.label.get') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'node.label.delete') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'org.add') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'config.send') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'config.app.send') IF NOT EXISTS;
INSERT INTO apollo.permission (id, name) VALUES (uuid(), 'scmp.sys.admin') IF NOT EXISTS;