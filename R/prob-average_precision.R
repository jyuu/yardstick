#' Area under the precision recall curve
#'
#' @description
#'
#' `average_precision()` is an alternative to `pr_auc()` that avoids any
#' ambiguity about what the value of `precision` should be when `recall == 0`
#' and there are not yet any false positive values (some say it should be `0`,
#' others say `1`, others say undefined).
#'
#' It computes a weighted average of the precision values returned from
#' [pr_curve()], where the weights are the increase in recall from the previous
#' threshold. See [pr_curve()] for the full curve.
#'
#' @details
#'
#' The computation for average precision is a weighted average of the precision
#' values. Assuming you have `n` rows returned from [pr_curve()], it is a sum
#' from `2` to `n`, multiplying the precision value `p_i` by the increase in
#' recall over the previous threshold, `r_i - r_(i-1)`.
#'
#' \deqn{AP = \sum (r_{i} - r_{i-1}) * p_i}
#'
#' By summing from `2` to `n`, the precision value `p_1` is never used. While
#' [pr_curve()] returns a value for `p_1`, it is technically undefined as
#' `tp / (tp + fp)` with `tp = 0` and `fp = 0`. A common convention is to use
#' `1` for `p_1`, but this metric has the nice property of avoiding the
#' ambiguity. On the other hand, `r_1` is well defined as long as there are
#' some events (`p`), and it is `tp / p` with `tp = 0`, so `r_1 = 0`.
#'
#' When `p_1` is defined as `1`, the `average_precision()` and `roc_auc()`
#' values are often very close to one another.
#'
#' @family class probability metrics
#' @templateVar metric_fn average_precision
#' @template return
#' @template multiclass-prob
#' @template event_first
#'
#' @inheritParams pr_auc
#'
#' @seealso
#'
#' [pr_curve()] for computing the full precision recall curve.
#'
#' [pr_auc()] for computing the area under the precision recall curve using
#' the trapezoidal rule.
#'
#' @template examples-binary-prob
#' @template examples-multiclass-prob
#'
#' @export
average_precision <- function(data, ...) {
  UseMethod("average_precision")
}

class(average_precision) <- c("prob_metric", "function")

#' @export
#' @rdname average_precision
average_precision.data.frame  <- function(data, truth, ...,
                                          estimator = NULL,
                                          na_rm = TRUE) {

  estimate <- dots_to_estimate(data, !!! enquos(...))

  metric_summarizer(
    metric_nm = "average_precision",
    metric_fn = average_precision_vec,
    data = data,
    truth = !!enquo(truth),
    estimate = !!estimate,
    estimator = estimator,
    na_rm = na_rm,
    ... = ...
  )

}

#' @export
#' @rdname average_precision
average_precision_vec <- function(truth, estimate,
                                  estimator = NULL, na_rm = TRUE, ...) {

  estimator <- finalize_estimator(truth, estimator, "average_precision")

  average_precision_impl <- function(truth, estimate) {
    average_precision_estimator_impl(truth, estimate, estimator)
  }

  metric_vec_template(
    metric_impl = average_precision_impl,
    truth = truth,
    estimate = estimate,
    na_rm = na_rm,
    estimator = estimator,
    cls = c("factor", "numeric"),
    ...
  )

}

average_precision_estimator_impl <- function(truth, estimate, estimator) {

  if (is_binary(estimator)) {
    average_precision_binary(truth, estimate)
  }
  else {
    # weights for macro / macro_weighted are based on truth frequencies
    # (this is the usual definition)
    truth_table <- matrix(table(truth), nrow = 1)
    w <- get_weights(truth_table, estimator)
    out_vec <- average_precision_multiclass(truth, estimate)
    weighted.mean(out_vec, w)
  }

}

average_precision_binary <- function(truth, estimate) {
  pr_list <- pr_curve_vec(truth, estimate)

  pr_recalls <- pr_list[["recall"]]
  pr_precisions <- pr_list[["precision"]]

  sum(diff(pr_recalls) * pr_precisions[-1])
}

average_precision_multiclass <- function(truth, estimate) {
  res_lst <- one_vs_all_impl(average_precision_binary, truth, estimate)
  rlang::flatten_dbl(res_lst)
}
