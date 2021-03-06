context("Recall")

# ------------------------------------------------------------------------------

lst <- data_powers()
tabl_2_1 <- lst$tabl_2_1
df_2_1 <- lst$df_2_1

test_that('Two class - Powers paper', {
  expect_equal(
    recall(df_2_1, truth = "truth", estimate = "prediction")[[".estimate"]],
    30/60
  )
  expect_equal(
    recall(tabl_2_1)[[".estimate"]],
    30/60
  )
  expect_equal(
    recall(df_2_1, truth = truth, estimate = pred_na)[[".estimate"]],
    26/(26+29)
  )
})

# ------------------------------------------------------------------------------

test_that("'micro' `NA` case is handled correctly", {

  estimate <- factor(c(rep("a", 2), rep("b", 2)))
  truth <- factor(rep("b", length(estimate)), levels(estimate))

  expect_equal(
    recall_vec(truth, estimate, estimator = "micro"),
    NA_real_
  )

})

# sklearn compare --------------------------------------------------------------

py_res <- read_pydata("py-recall")
r_metric <- recall

test_that('Two class - sklearn equivalent', {
  expect_equal(
    r_metric(two_class_example, truth, predicted)[[".estimate"]],
    py_res$binary
  )
})

test_that('Multi class - sklearn equivalent', {
  expect_equal(
    r_metric(hpc_cv, obs, pred)[[".estimate"]],
    py_res$macro
  )
  expect_equal(
    r_metric(hpc_cv, obs, pred, "micro")[[".estimate"]],
    py_res$micro
  )
  expect_equal(
    r_metric(hpc_cv, obs, pred, "macro_weighted")[[".estimate"]],
    py_res$weighted
  )
})
