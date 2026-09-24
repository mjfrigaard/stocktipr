test_that("app_ui renders each module once", {
  html <- as.character(app_ui())

  for (id in c("inputs-tickers", "outputs-value_boxes", "download-download")) {
    expect_equal(lengths(regmatches(html, gregexpr(sprintf('id="%s"', id), html))), 1)
  }
})

test_that("stocktipr_theme returns a bslib theme", {
  expect_true(bslib::is_bs_theme(stocktipr_theme()))
})
