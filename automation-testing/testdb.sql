CREATE KEYSPACE cycling
  WITH REPLICATION = {
   'class' : 'NetworkTopologyStrategy',
   'dc1'  : 1
  };


CREATE TABLE cycling.race_winners (
   race_name text,
   race_position int,
   cyclist_name text,
   PRIMARY KEY (race_name, race_position));

alter table cycling.race_winners with GC_GRACE_SECONDS = 360;


insert into cycling.race_winners (race_name, race_position, cyclist_name) values ('race1', 1, 'karl');
insert into cycling.race_winners (race_name, race_position, cyclist_name) values ('race2', 1, 'karl');
insert into cycling.race_winners (race_name, race_position, cyclist_name) values ('race3', 1, 'karl');
insert into cycling.race_winners (race_name, race_position, cyclist_name) values ('race4', 1, 'karl');

CREATE TABLE cycling.rank_by_year_and_name (
  race_year int,
  race_name text,
  cyclist_name text,
  rank int,
  PRIMARY KEY ((race_year, race_name), rank)
);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2023, 'Tour de France', 'Jonas Vingegaard', 1);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2023, 'Tour de France', 'Tadej Pogacar', 2);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2023, 'Tour de France', 'Adam Yates', 3);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2023, 'Giro d''Italia', 'Primoz Roglic', 1);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2023, 'Giro d''Italia', 'Geraint Thomas', 2);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2023, 'Giro d''Italia', 'Joao Almeida', 3);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2024, 'Tour de France', 'Tadej Pogacar', 1);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2024, 'Tour de France', 'Jonas Vingegaard', 2);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2024, 'Tour de France', 'Remco Evenepoel', 3);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2024, 'Vuelta a España', 'Primoz Roglic', 1);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2024, 'Vuelta a España', 'Ben O''Connor', 2);

INSERT INTO cycling.rank_by_year_and_name (race_year, race_name, cyclist_name, rank)
VALUES (2024, 'Vuelta a España', 'Enric Mas', 3);

CREATE INDEX ryear ON cycling.rank_by_year_and_name (race_year);
