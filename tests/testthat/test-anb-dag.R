context("bnc dag")

test_that("bnc_dag", {
# Nominal
  e <- list(A = 'B', B = NULL)
  g <- graph::graphNEL(nodes = LETTERS[1:2], edgeL = e, edgemode = "directed")
  bd <- bnc_dag(dag = g, class = 'A')
  expect_is(bd, 'bnc_dag')
  expect_identical(bd$.class, 'A')
  expect_identical(bd$.dag, g)
  expect_identical(features(bd), 'B')
  expect_identical(vars(bd), setNames(nm = LETTERS[2:1]))
  expect_identical(bd$.families, list(B = LETTERS[2:1], A = 'A'))
# Just class
  g <- graph::graphNEL(nodes = LETTERS[1], edgemode = "directed")
  bd <- bnc_dag(dag = g, class = 'A')
  expect_is(bd, 'bnc_dag')
  expect_identical(bd$.class, 'A')
  expect_identical(bd$.dag, g)
  expect_identical(features(bd), character())
  expect_identical(vars(bd), setNames(nm = 'A'))
  expect_identical(bd$.families, list(A='A'))
# Class not parent of all other nodes
  e <- list(A = 'B',B = NULL)
  g <- graph::graphNEL(nodes = LETTERS[1:3], edgeL = e, edgemode = "directed")
  expect_error(bnc_dag(dag = g, class = 'A'), "last")
})

test_that("Accessors", {
# Nominal  
  skip_if_not_installed('gRbase')
  set.seed(0)
  ran <- random_aug_nb_dag('z', letters[-26], maxpar = 5, wgt = 0.8)
  dg <- bnc_dag(ran, class = 'z')
  expect_identical(unname(sort(vars(dg))), letters)  
})

test_that("feature families nominal", {
  n <- nbcar()
  a <- feature_families(n)
  expect_equal(length(a), 6)
  expect_equal(a[[1]], c('buying', 'class'))
})