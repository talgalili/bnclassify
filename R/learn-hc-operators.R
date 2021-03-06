get_candidate_features <- function(bnc_dag, features_to_include) {
  setdiff(features_to_include, features(bnc_dag))
}
# Forms dags by conditioninng each not-included feature on each of the supernodes
includes_in_supernodes <- function(bnc_dag, features_to_include) {
  stopifnot(is_semi_naive(bnc_dag))
  to_include <- get_candidate_features(bnc_dag, features_to_include)
  # Nothing to do if there are no features in the dag
  if (length(to_include) == 0) return(NULL)  
  # Get the supernodes here for efficiency (to not repeat it inside each call)
  supernodes <- not_cci(x = bnc_dag)    
  l <- lapply(to_include, augment_supernodes, bnc_dag, supernodes)
  # Do I need names? With is use.names = FALSE it is faster.
  unlist(l, recursive = FALSE, use.names = FALSE)
}
augment_supernodes <- function(new_node, bnc_dag, supernodes) {
  if (length(supernodes) == 0) return(list())
  stopifnot(is_just(supernodes, "list"))
  augmented <- add_feature(new_node, bnc_dag)
  dags <- lapply(supernodes, add_feature_parents, new_node, augmented)
  stopifnot(all(vapply(dags, is_semi_naive, FUN.VALUE = logical(1))))
  dags
}
merge_supernodes <- function(bnc_dag) {
  stopifnot(is_semi_naive(bnc_dag))
  # if (length(features(bnc_dag)) == 0) return(NULL) The check below should work
  supernodes <- not_cci(bnc_dag)
  # No pairs   
  if (length(supernodes) < 2) return(NULL)
  pairs <- combn(seq_along(supernodes), 2)
  child <- supernodes[pairs[1, ]]
  parent <- supernodes[pairs[2, ]]
  dags <- mapply(relate_supernodes, child, parent, MoreArgs = list(x = bnc_dag),
                 SIMPLIFY = FALSE)
  stopifnot(all(vapply(dags, is_semi_naive, FUN.VALUE = logical(1))))  
  dags
}
includes <- function(bnc_dag, features_to_include) {
  to_include <- get_candidate_features(bnc_dag, features_to_include)
  lapply(to_include, add_feature, bnc_dag)
}
excludes <- function(bnc_dag) {
  lapply(features(bnc_dag), remove_feature, bnc_dag)  
}
fssj_step <- function(bnc_dag, features_to_include, ...) {
  append(includes(bnc_dag, features_to_include), 
         includes_in_supernodes(bnc_dag,features_to_include))
}
bsej_step <- function(bnc_dag, ...) {
  c(excludes(bnc_dag), 
    merge_supernodes(bnc_dag))
}
#' Arcs that do not invalidate the tree-like structure
#' 
#' @param ... Ignored.
#' @keywords internal
augment_ode <- function(bnc_dag, ...) {
  arcs <- augment_ode_arcs(bnc_dag)
  if (length(arcs) == 0) return(NULL)
  dags <- mapply(add_feature_parents, arcs[, 'from'], arcs[, 'to'], 
                 MoreArgs = list(x = bnc_dag), SIMPLIFY = FALSE)
  stopifnot(all(vapply(dags, is_ode, FUN.VALUE = logical(1))))
  dags
}
#' Returns augmenting arcs that do not invalidate the ODE. 
#' 
#' @keywords internal
#' @return a character matrix. NULL if no arcs can be added.
augment_ode_arcs <- function(bnc_dag) {
  stopifnot(is_ode(bnc_dag))
  orphans <- feature_orphans(bnc_dag) 
  # An ODE must have at least one orphan
  stopifnot(length(orphans) >= 1)  
  if (length(orphans) == 1) return(matrix(character(), ncol = 2))
  non_orphans <- setdiff(features(bnc_dag), orphans)
  arcs <- arcs_to_orphans(orphans, non_orphans)
  arcs <- discard_cycles(arcs, bnc_dag)
  # discard equivalent arcs
  discard_reversed(arcs)
}
# Returns each possible ode-augmenting arc. It also includes equivalent arcs among orphans --- e.g., A -> B is yields an equivalent structure as B -> A --- but this is handled by discard_reversed. Returns a data frame.
arcs_to_orphans <- function(orphans, non_orphans) {
  # Check they are disjoint
  stopifnot(are_disjoint(orphans, non_orphans))
  # If no orphans return empty
  if (length(orphans) == 0) return(NULL)
  # Add an arc from each non_orphans to each ode orphans 
  a <- expand.grid(from = non_orphans, to = orphans, stringsAsFactors = FALSE, 
                   KEEP.OUT.ATTRS = FALSE)
  # Add each orphan combination, too.
  if (length(orphans) > 1) {
    b <- t(combn(orphans, 2))
    # Add the reversed arcs, too (b[, 2:1])
    b <- rbind(b, b[, 2:1])
    # rbind requires same column names
    colnames(b) <- c('from', 'to')
    a <- rbind(a, b)  
  }
  as.matrix(a)
}
# Remove from arcs_df arcs that would introduce a cycle in bnc_dag
discard_cycles <- function(arcs_df, bnc_dag) {
  stopifnot(is.matrix(arcs_df), is.character(arcs_df))
  from <- unique(arcs_df[, 'from'])
  ancestors <- lapply(from, get_ancestors, families(bnc_dag))
  # the [from] to ensures that ancestors and potential_children are in same order
  potential_children <- tapply(arcs_df[, 'to'], arcs_df[, 'from'],
                              identity)[from]
  cycle_free <- mapply(setdiff, potential_children, ancestors, 
                       SIMPLIFY = FALSE)
  cycle_free_mat <- unlist_keepnames(cycle_free)
  colnames(cycle_free_mat) <- c('to', 'from')
  cycle_free_mat[, c('from', 'to')]
}
discard_reversed <- function(matrix) {
  if (nrow(matrix) == 0) return(matrix(character(), ncol = 2))
  # Remove name so that reversed is the exact reflection
  remember_names <- colnames(matrix)
  matrix <- unname(matrix)
  reversed <- matrix[, rev(seq_len(ncol(matrix)))]
  stopifnot(identical(matrix, reversed[, 2:1]))
  unique <- rep(FALSE, nrow(matrix))
  # Count last element as unique
  unique[length(unique)] <- TRUE
  for (row in rev(seq_len(nrow(matrix) - 1))) {
    this_row <- matrix[row, ]
    unique[row] <- !any(apply(reversed[unique, , drop = FALSE], 1, 
                              identical, this_row))
  }
  matrix <- matrix[ unique, , drop = FALSE]
  colnames(matrix) <- remember_names
  matrix
}

augment_ode_sp <- function(bnc_dag, features_to_include, dataset, 
                           smooth, k) {
  rm(features_to_include) # ignored
  # Select superparent:
  sp_children <- superparent_children(bnc_dag)
  if (length(sp_children) < 1) return(NULL)
  # Select best superparent (could be skipped if there is just one)
  sp_dags <- mapply(add_feature_parents, names(sp_children), sp_children, 
                MoreArgs = list(x = bnc_dag), SIMPLIFY = FALSE)
  scores <- cv(sp_dags, dataset = dataset, k = k, dag = FALSE, smooth = smooth)
  best_ind <- max_random(scores)  
  # Form a dag for each possible child of the superparent
  superparent <- names(sp_children)[best_ind]
  children <- sp_children[[superparent]]
  dags <- lapply(children, add_feature_children, superparent, x = bnc_dag)
  stopifnot(all(vapply(dags, is_ode, FUN.VALUE = logical(1)))) 
  dags
}
#' Return nodes which can be superparents along with their possible children.
#' 
#' @keywords internal 
#' @return list of \code{search_state}. NULL if no orphans
superparent_children <- function(bnc_dag) {
  stopifnot(is_ode(bnc_dag))
  orphans <- feature_orphans(bnc_dag)
  stopifnot(length(orphans) >= 1) 
  if (length(orphans) == 1) return(NULL)
  features <- features(bnc_dag)
  #possible children of each feature: orphans != itself and its ancestors 
  ancestors <- lapply(features, get_ancestors, families(bnc_dag))
  fs_children <- mapply(ok_children, feature = features, ancestors = ancestors, 
         MoreArgs = list(orphans = orphans), SIMPLIFY = FALSE)
  # a feature with at least 1 possible child can be a superparent 
  fs_children[element_lengths(fs_children) > 0]
}
# Acceptable children for a feature
ok_children <- function(feature, ancestors, orphans) {
  setdiff(orphans, c(feature, ancestors))
}