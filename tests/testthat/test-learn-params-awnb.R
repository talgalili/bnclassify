context("AWNB") 

test_that("one tree", {
  set.seed(0)
  a <- awnb('class', car, bootstrap_size = 0.5, trees = 1)
  expect_equal(as.vector(a['buying']), 0.5773503, tolerance = 1e-5)
  expect_equal(as.vector(a['doors']), 0.3779645, tolerance = 1e-5)
  expect_equal(as.vector(a['persons']), 1)
  set.seed(0)
})

test_that("one two trees", {  
  a <- awnb('class', car, bootstrap_size = 0.5, trees = 2)
  expect_true(is_perm(names(a), colnames(car)[-7]))
  expect_equal(as.vector(a['buying']), 0.5773503, tolerance = 1e-5)
  expect_equal(as.vector(a['doors']), 0.3931064, tolerance = 1e-5)
  expect_equal(as.vector(a['persons']), 1)
  set.seed(0)
  a <- awnb('Class', voting, bootstrap_size = 0.5, trees = 10)
  expect_true(is_perm(names(a), colnames(voting)[-17]))
  expect_equal(as.vector(a['superfund_right_to_sue']), 0.21019141, tolerance = 1e-5)
  expect_equal(as.vector(a['mx_missile']), 0.30487476, tolerance = 1e-5)
  expect_equal(as.vector(a['immigration']), 0.39963413)
})

test_that("one no tree", {
  expect_error(awnb('Class', dataset = voting[1:2, ],  
                    bootstrap_size = 0.5, trees = 10), "empty")
})

test_that("Incomplete data" , {
  a <- nb('Class', voting)
  b <- lpawnb(a, voting, smooth = 1, trees = 1, bootstrap_size = 0.1)
  c <- lp(a, voting, smooth = 1)
  expect_equal(params(b), params(set_weights(c, b$.weights)))
})