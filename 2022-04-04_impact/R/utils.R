read_sql <- function(filename) {
  paste(readLines(filename), collapse = "\n")
}

read_csv <- function(...) {
  utils::read.csv(..., stringsAsFactors = FALSE)
}

merge_by_common_cols <- function(d1, d2, ...){
  merge(d1, d2, by = intersect(names(d1), names(d2)), ...)
}

not_is_finite <- function(x) {
  is.numeric(x) & !is.finite(x)
}

set_as_na <- function(x) {
  x <-NA
}

'%!in%' <- function(x,y)!('%in%'(x,y))

signif.ceiling <- function(x, n){
  pow <- floor( log10( abs(x) ) ) + 1 - n
  y <- ceiling(x / 10 ^ pow) * 10^pow
  # handle the x = 0 case
  y[x==0] <- 0
  y
}


signif.floor <- function(x, n){
  pow <- floor( log10( abs(x) ) ) + 1 - n
  y <- floor(x / 10 ^ pow) * 10^pow
  # handle the x = 0 case
  y[x==0] <- 0
  y
}

grepv <- function(patterns, value, is_and = TRUE) {
  stopifnot(length(patterns) >= 1)
  j <- rep(0, length(value))
  
  for(i in patterns) {
    j <- j + grepl(i, value)
  }
  
  if(is_and) {
    v <- j == length(patterns)
  } else {
    v <- j >= 1
  }
  return(v)
}

data_frmae <- function(...) {
  data.frame(..., stringsAsFactors = FALSE)
}

sql_in <- function (items, text_item = TRUE) {
  items <- paste(if (text_item) 
    squote(items)
    else items, collapse = ", ")
  sprintf("(%s)", items)
}