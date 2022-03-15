CREATE SEQUENCE metadata_id_seq;

CREATE TABLE metadata (
  id              integer DEFAULT nextval('metadata_id_seq'),
  touchstone      text NOT NULL,
  modelling_group text NOT NULL,
  disease         text NOT NULL,
  version         integer DEFAULT 1,
  creation_date   date DEFAULT now()
);

ALTER SEQUENCE metadata_id_seq OWNED BY metadata.id;

CREATE TABLE stochastic_1 (
  run_id                                 integer,
  year                                   integer,
  age                                    integer,
  country                                varchar(3),
  cohort_size                            real,
  "cases_yf-no-vaccination"              double precision,
  "cases_yf-preventive-default"          double precision,
  "cases_yf-preventive-ia2030_target"    double precision,
  "cases_yf-routine-default"             double precision,
  "cases_yf-routine-ia2030_target"       double precision,
  "dalys_yf-no-vaccination"              double precision,
  "dalys_yf-preventive-default"          double precision,
  "dalys_yf-preventive-ia2030_target"    double precision,
  "dalys_yf-routine-default"             double precision,
  "dalys_yf-routine-ia2030_target"       double precision,
  "deaths_yf-no-vaccination"             double precision,
  "deaths_yf-preventive-default"         double precision,
  "deaths_yf-preventive-ia2030_target"   double precision,
  "deaths_yf-routine-default"            double precision,
  "deaths_yf-routine-ia2030_target"      double precision
);
