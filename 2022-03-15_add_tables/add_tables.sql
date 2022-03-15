CREATE SEQUENCE metadata_id_seq;

CREATE TABLE metadata (
  id              integer NOT NULL DEFAULT nextval('metadata_id_seq'),
  touchstone      text NOT NULL,
  modelling_group text NOT NULL,
  disease         text NOT NULL,
  version         integer NOT NULL DEFAULT 1,
  creation_date   date NOT NULL DEFAULT now()
);

ALTER SEQUENCE metadata_id_seq OWNED BY metadata.id;

CREATE TABLE stochastic_1 (
  run_id                                 integer,
  year                                   integer,
  age                                    integer,
  country                                varchar(3),
  cohort_size                            real,
  "cases_yf-no-vaccination"              double,
  "cases_yf-preventive-default"          double,
  "cases_yf-preventive-ia2030_target"    double,
  "cases_yf-routine-default"             double,
  "cases_yf-routine-ia2030_target"       double,
  "dalys_yf-no-vaccination"              double,
  "dalys_yf-preventive-default"          double,
  "dalys_yf-preventive-ia2030_target"    double,
  "dalys_yf-routine-default"             double,
  "dalys_yf-routine-ia2030_target"       double,
  "deaths_yf-no-vaccination"             double,
  "deaths_yf-preventive-default"         double,
  "deaths_yf-preventive-ia2030_target"   double,
  "deaths_yf-routine-default"            double,
  "deaths_yf-routine-ia2030_target"      double
);
