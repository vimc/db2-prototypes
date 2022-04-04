#include <R.h>
#include <Rinternals.h>
#include <stddef.h>

#define MAX_VACCINES 20

double prod_1_minus(double *x, size_t len);

// This function modifies some of its inputs:
//
// outcome_no_adj
void compute_thing1(size_t n, double *prop_with_n_vaccines, double *scale,
                    double *outcome_no, double *outcome_no_adj, double *outcome_vac_adj,
                    double *result) {
  double novac_surv[MAX_VACCINES], prod[MAX_VACCINES];
  double outcome_adj = 0.0;

  // adjusted mortality for people with k vaccines
  for (size_t i = 0; i < n; ++i) {
    outcome_no_adj[i] = outcome_vac_adj[i];
    prod[i] = 1 - prod_1_minus(outcome_no_adj, n);
    if (i == 0) {
      novac_surv[0] = 1;
    } else {
      novac_surv[i] = (1 - outcome_no[i]) * novac_surv[i - 1];
    }
    outcome_adj += prop_with_n_vaccines[i] * scale[i] * prod[i];
  }

  double result_novac = scale[n - 1] * (1 - novac_surv[n - 1]);
  double result_impact = result_novac - outcome_adj;
  result[0] = result_impact;
  result[1] = result_novac;
}

double prod_1_minus(double *x, size_t len) {
  double ret = 1 - x[0];
  for (size_t i = 1; i < len; ++i) {
    ret *= (1 - x[i]);
  }
  return ret;
}

void compute_thing(size_t ngroup, int *len, double *prop_with_n_vaccines,
                   double *death_scale, double *death_no, double *death_no_adj, double *death_vac_adj,
                   double *daly_scale, double *daly_no, double *daly_no_adj, double *daly_vac_adj,
                   double *result) {
  for (size_t i = 0; i < ngroup; ++i) {
    size_t n = len[i];
    compute_thing1(n, prop_with_n_vaccines,
                   death_scale, death_no, death_no_adj, death_vac_adj,
                   result);
    compute_thing1(n, prop_with_n_vaccines,
                   daly_scale, daly_no, daly_no_adj, daly_vac_adj,
                   result + 2);
    prop_with_n_vaccines += n;
    death_scale += n;
    death_no += n;
    death_no_adj += n;
    death_vac_adj += n;
    daly_scale += n;
    daly_no += n;
    daly_no_adj += n;
    daly_vac_adj += n;
    result += 4;
  }
}

// len is the rle if the main index, everything else is a column from the df
SEXP r_compute_thing(SEXP len, SEXP prop_with_n_vaccines,
                     SEXP death_scale, SEXP death_no, SEXP death_no_adj, SEXP death_vac_adj,
                     SEXP daly_scale, SEXP daly_no, SEXP daly_no_adj, SEXP daly_vac_adj) {
  size_t ngroup = LENGTH(len);
  SEXP result = PROTECT(allocVector(REALSXP, ngroup * 4));
  death_no_adj = PROTECT(duplicate(death_no_adj));
  daly_no_adj = PROTECT(duplicate(daly_no_adj));

  double *a = REAL(death_no_adj);
  double *b = REAL(death_vac_adj);
  
  compute_thing(ngroup, INTEGER(len), REAL(prop_with_n_vaccines),
                REAL(death_scale), REAL(death_no), a, b,
                REAL(daly_scale), REAL(daly_no), REAL(daly_no_adj), REAL(daly_vac_adj),
                REAL(result));
  UNPROTECT(3);
  return result;
}
