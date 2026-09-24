test_that("with_logging returns the value of the expression", {
  expect_equal(with_logging(1 + 1, context = "test"), 2)
})

test_that("with_logging re-throws errors", {
  expect_error(with_logging(stop("boom"), context = "test"), "boom")
})

test_that("with_logging muffles warnings and still returns the value", {
  expect_no_warning(res <- with_logging({
    warning("careful")
    "done"
  }, context = "test"))
  expect_equal(res, "done")
})

test_that("%||% returns the right-hand side only for NULL", {
  expect_equal(NULL %||% "b", "b")
  expect_equal("a" %||% "b", "a")
  expect_equal(NA %||% "b", NA)
})

test_that("app_set_log_threshold sets every app namespace", {
  old <- logger::log_threshold(namespace = "stocktipr/app")
  on.exit(app_set_log_threshold(old))

  expect_invisible(app_set_log_threshold(logger::WARN))
  for (ns in c("stocktipr/app", "stocktipr/inputs", "stocktipr/download")) {
    expect_equal(logger::log_threshold(namespace = ns), logger::WARN, ignore_attr = TRUE)
  }
})
