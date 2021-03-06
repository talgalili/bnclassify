# Creates an augmented naive Bayes with structure but no parameters.
bnc_dag <- function(dag, class) {
  families <- graphNEL2families(dag, class)  
#   Save dag, class, features,and call 
  make_bnc_dag(class = class, families = families, graphNEL = dag)
}
make_bnc_dag <- function(class, families, graphNEL) {
  # Not checking families for efficiency; they are checked in bnc_dag anyway
  obj <- list(.dag = graphNEL, .class = class, .families = families)
  class(obj) <- 'bnc_dag'
  obj
}
# Checks it is a valid bnc_dag object 
check_bnc_dag <- function(x) {
  check_bnc_dag_basic(x)
  # Check families
  check_anb_families(families(x), class_var(x))  
} 
check_bnc_dag_basic <- function(x) {
  class <- class_var(x)
  features <- features(x)
  # This also checks for class.
  check_features(features = features, class = class)
  stopifnot(identical(vars(x), setNames(nm = c(features, class))))
}
#' To graphNEL. 
#' @export 
#' @param x a \code{\link{bnc_dag_object}} object. The Bayesian network structure.
as_graphNEL <- function(x) {
  stopifnot(inherits(x, "bnc_dag"))
  x$.dag
}
#' @export 
#' @describeIn  bnc_dag_object Returns the class variable.
class_var <- function(x) {
  stopifnot(inherits(x, "bnc_dag"))
  x$.class
}
#' @export 
#' @describeIn  bnc_dag_object Returns the features.
features <- function(x) {
  setdiff(vars(x), class_var(x))
}
#' @export 
#' @describeIn  bnc_dag_object Returns all variables (i.e., features + class).
vars <- function(x) {
  setNames(nm = get_family_vars(families(x)))
}
#' @export 
#' @describeIn  bnc_dag_object Returns the family of each variable.
families <- function(x) {
  stopifnot(inherits(x, "bnc_dag"))
  x$.families
}
# # Returns all feature families excluding the class variable
# feature_families <- function(x) {
#   feature_fams <- families(x)[features(x)]
#   lapply(feature_fams, family_features, class_var(x))
# }
#' @export 
#' @describeIn  bnc_dag_object Returns the family of each feature.
feature_families <- function(x) {
  families(x)[features(x)]
}