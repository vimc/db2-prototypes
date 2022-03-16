CREATE SEQUENCE stochastic_file_id_seq;

CREATE TABLE stochastic_file (
  id              integer DEFAULT nextval('stochastic_file_id_seq'),
  touchstone      text NOT NULL,
  modelling_group text NOT NULL,
  disease         text NOT NULL,
  is_cohort       boolean NOT NULL,
  is_under5       boolean NOT NULL,
  version         integer DEFAULT 1,
  creation_date   date DEFAULT now()
);

ALTER SEQUENCE stochastic_file_id_seq OWNED BY stochastic_file.id;

CREATE TABLE stochastic_1 (
  run_id                                 integer,
  year                                   integer,
  country                                varchar(3),
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

CREATE TABLE stochastic_2 (
  run_id                                 integer,
  year                                   integer,
  country                                varchar(3),
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

CREATE TABLE stochastic_3 (
  run_id                                 integer,
  year                                   integer,
  country                                varchar(3),
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

CREATE TABLE stochastic_4 (
  run_id                                 integer,
  year                                   integer,
  country                                varchar(3),
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
