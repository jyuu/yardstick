#' Gain capture
#'
#' `gain_capture()` is a measure of performance similar to an AUC calculation,
#' but applied to a gain curve.
#'
#' `gain_capture()` calculates the area _under_ the gain curve, but _above_
#' the baseline, and then divides that by the area _under_ a perfect gain curve,
#' but _above_ the baseline. It is meant to represent the amount of potential
#' gain "captured" by the model.
#'
#' The `gain_capture()` metric is identical to the _accuracy ratio (AR)_, which
#' is also sometimes called the _gini coefficient_. These two are generally
#' calculated on a cumulative accuracy profile curve, but this is the same as
#' a gain curve. See the Engelmann reference for more information.
#'
#' @family class probability metrics
#' @templateVar metric_fn gain_capture
#' @template event_first
#' @template return
#' @template multiclass-prob
#'
#' @inheritParams pr_auc
#'
#' @author Max Kuhn
#'
#' @references
#'
#' Engelmann, Bernd & Hayden, Evelyn & Tasche, Dirk (2003).
#' "Measuring the Discriminative Power of Rating Systems,"
#' Discussion Paper Series 2: Banking and Financial Studies 2003,01,
#' Deutsche Bundesbank.
#'
#' @seealso
#'
#' [gain_curve()] to compute the full gain curve.
#'
#' @template examples-binary-prob
#' @template examples-multiclass-prob
#' @examples
#' # ---------------------------------------------------------------------------
#' # Visualize gain_capture()
#'
#' # Visually, this represents the area under the black curve, but above the
#' # 45 degree line, divided by the area of the shaded triangle.
#' library(ggplot2)
#' autoplot(gain_curve(two_class_example, truth, Class1))
#'
#' @export
gain_capture <- function(data, ...) {
  UseMethod("gain_capture")
}

class(gain_capture) <- c("prob_metric", "function")

#' @rdname gain_capture
#' @export
gain_capture.data.frame <- function(data, truth, ...,
                                    estimator = NULL,
                                    na_rm = TRUE) {

  estimate <- dots_to_estimate(data, !!! enquos(...))

  metric_summarizer(
    metric_nm = "gain_capture",
    metric_fn = gain_capture_vec,
    data = data,
    truth = !! enquo(truth),
    estimate = !! estimate,
    estimator = estimator,
    na_rm = na_rm,
    ... = ...
  )

}

#' @export
#' @rdname gain_capture
gain_capture_vec <- function(truth, estimate,
                             estimator = NULL,
                             na_rm = TRUE,
                             ...) {

  estimator <- finalize_estimator(truth, estimator, "gain_capture")

  gain_capture_impl <- function(truth, estimate) {
    gain_capture_estimator_impl(truth, estimate, estimator)
  }

  metric_vec_template(
    metric_impl = gain_capture_impl,
    truth = truth,
    estimate = estimate,
    na_rm = na_rm,
    estimator = estimator,
    cls = c("factor", "numeric"),
    ...
  )

}

gain_capture_estimator_impl <- function(truth, estimate, estimator) {

  if(is_binary(estimator)) {
    gain_capture_binary(truth, estimate)
  } else {
    truth_table <- matrix(table(truth), nrow = 1)
    w <- get_weights(truth_table, estimator)
    out_vec <- gain_capture_multiclass(truth, estimate)
    weighted.mean(out_vec, w)
  }

}

gain_capture_binary <- function(truth, estimate) {

  gain_list <- gain_curve_vec(truth, estimate)

  gain_to_0_auc <- auc(
    x = gain_list[[".percent_tested"]],
    y = gain_list[[".percent_found"]]
  )

  scaler <- 1 / (100 ^ 2)
  height <- 100
  width <- 100
  baseline <- 0.5

  gain_to_0_auc <- gain_to_0_auc * scaler

  # perfect = value at the elbow of the perfect gain chart
  .n_events <- gain_list[[".n_events"]]
  .n <- gain_list[[".n"]]
  slope <- 1 / (max(.n_events) / dplyr::last(.n))
  perfect <- height / slope

  # perfect triangle
  perf_triang <- (perfect * height) / 2

  # perfect rectangle
  perf_rect <- (width - perfect) * height

  perf_auc <- (perf_rect + perf_triang) * scaler

  # calculate capture ratio = fraction of area captured
  # under the gain curve, but above the baseline, and relative to a
  # perfect capture score
  (gain_to_0_auc - baseline) / (perf_auc - baseline)

}

gain_capture_multiclass <- function(truth, estimate) {
  res_lst <- one_vs_all_impl(gain_capture_binary, truth, estimate)
  rlang::flatten_dbl(res_lst)
}
