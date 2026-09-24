test_that("mod_download_ui ids match the mod_download_server namespace", {
  html <- as.character(mod_download_ui("download"))

  expect_match(html, 'id="download-format"', fixed = TRUE)
  expect_match(html, 'id="download-download"', fixed = TRUE)

  shiny::testServer(
    mod_download_server,
    args = list(id = "download", inputs_r = shiny::reactive(NULL), perf_r = shiny::reactive(NULL)),
    {
      expect_equal(session$ns("format"), "download-format")
      expect_equal(session$ns("download"), "download-download")
    }
  )
})

test_that("mod_download_server renders an HTML report", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  inputs_r <- shiny::reactive(list(
    tickers = "LLY",
    from = as.Date("2023-01-01"),
    to = as.Date("2023-03-31"),
    vol_window = 30L
  ))
  perf_r <- shiny::reactive(data.frame(
    symbol = "LLY",
    ann_return = 0.25,
    ann_vol = 0.18,
    sharpe = 1.39
  ))

  shiny::testServer(mod_download_server, args = list(inputs_r = inputs_r, perf_r = perf_r), {
    session$setInputs(format = "html")
    report <- output$download

    expect_true(file.exists(report))
    expect_gt(file.size(report), 0)
    expect_match(readLines(report, n = 1), "<!DOCTYPE html>", fixed = TRUE)
  })
})
