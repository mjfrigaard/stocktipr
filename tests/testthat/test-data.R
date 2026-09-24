test_that("default_tickers is a non-empty character vector", {
  expect_type(default_tickers, "character")
  expect_gt(length(default_tickers), 0)
  expect_false(anyDuplicated(default_tickers) > 0)
})

test_that("get_stock_returns computes log returns and drops the first row per symbol", {
  prices <- data.frame(
    symbol = rep(c("AAA", "BBB"), each = 3),
    date = rep(as.Date(c("2023-01-01", "2023-01-02", "2023-01-03")), 2),
    adjusted = c(100, 105, 110, 200, 210, 220)
  )

  returns <- get_stock_returns(prices)

  expect_named(returns, c("symbol", "date", "daily_return"))
  expect_equal(nrow(returns), 4)
  expect_false(anyNA(returns$daily_return))
  expect_equal(returns$daily_return[1], log(105 / 100))
})

test_that("get_stock_returns sorts by date before lagging", {
  prices <- data.frame(
    symbol = "AAA",
    date = as.Date(c("2023-01-03", "2023-01-01", "2023-01-02")),
    adjusted = c(110, 100, 105)
  )

  returns <- get_stock_returns(prices)

  expect_equal(returns$date, as.Date(c("2023-01-02", "2023-01-03")))
  expect_equal(returns$daily_return, log(c(105 / 100, 110 / 105)))
})

test_that("summarise_performance annualises return, volatility and Sharpe", {
  r <- c(0.01, 0.02, -0.01)
  returns <- data.frame(
    symbol = "AAA",
    date = as.Date(c("2023-01-01", "2023-01-02", "2023-01-03")),
    daily_return = r
  )

  perf <- summarise_performance(returns)

  expect_equal(nrow(perf), 1)
  expect_equal(perf$ann_return, mean(r) * 252)
  expect_equal(perf$ann_vol, sd(r) * sqrt(252))
  expect_equal(perf$sharpe, (mean(r) * 252) / (sd(r) * sqrt(252)))
})

test_that("summarise_performance returns one row per symbol", {
  returns <- data.frame(
    symbol = c("AAA", "AAA", "BBB", "BBB"),
    date = rep(as.Date(c("2023-01-01", "2023-01-02")), 2),
    daily_return = c(0.01, 0.02, 0.015, 0.025)
  )

  perf <- summarise_performance(returns)

  expect_setequal(perf$symbol, c("AAA", "BBB"))
})

test_that("compute_rolling_vol is NA until the window is complete", {
  r <- c(0.01, 0.02, -0.01, 0.015, 0.02)
  returns <- data.frame(
    symbol = "AAA",
    date = as.Date("2023-01-01") + 0:4,
    daily_return = r
  )

  vol <- compute_rolling_vol(returns, window = 3)

  expect_equal(nrow(vol), 5)
  expect_true(all(is.na(vol$rolling_vol[1:2])))
  expect_equal(vol$rolling_vol[3], sd(r[1:3]) * sqrt(252))
})

test_that("compute_rolling_vol restarts the window for each symbol", {
  returns <- data.frame(
    symbol = rep(c("AAA", "BBB"), each = 3),
    date = rep(as.Date("2023-01-01") + 0:2, 2),
    daily_return = c(0.01, 0.02, -0.01, 0.03, 0.01, 0.02)
  )

  vol <- compute_rolling_vol(returns, window = 2)

  expect_true(is.na(vol$rolling_vol[vol$symbol == "BBB"][1]))
  expect_false(is.na(vol$rolling_vol[vol$symbol == "BBB"][2]))
})
