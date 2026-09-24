inputs_html <- function(id = "inputs") {
  as.character(bslib::layout_sidebar(sidebar = mod_inputs_ui(id)))
}

test_that("mod_inputs_ui namespaces every input", {
  html <- inputs_html("myinputs")

  for (input_id in c("tickers", "dates", "vol_window", "fetch")) {
    expect_match(html, sprintf('id="myinputs-%s"', input_id), fixed = TRUE)
  }
})

test_that("mod_inputs_ui preselects tickers from default_tickers", {
  html <- inputs_html()

  for (tkr in default_tickers[1:3]) {
    expect_match(html, sprintf('<option value="%s" selected>', tkr), fixed = TRUE)
  }
})

test_that("mod_inputs_ui includes the download card", {
  html <- inputs_html()

  expect_match(html, 'id="download-format"', fixed = TRUE)
  expect_match(html, 'id="download-download"', fixed = TRUE)
})

test_that("mod_inputs_server returns the current inputs as a list", {
  shiny::testServer(mod_inputs_server, args = list(), {
    session$setInputs(
      tickers = c("LLY", "MRK"),
      dates = as.Date(c("2023-01-01", "2023-12-31")),
      vol_window = 30L,
      fetch = 1
    )
    inp <- session$returned()

    expect_equal(inp$tickers, c("LLY", "MRK"))
    expect_equal(inp$from, as.Date("2023-01-01"))
    expect_equal(inp$to, as.Date("2023-12-31"))
    expect_equal(inp$vol_window, 30L)
    expect_equal(inp$fetch, 1)
  })
})

test_that("mod_inputs_server updates when tickers change", {
  shiny::testServer(mod_inputs_server, args = list(), {
    session$setInputs(tickers = "LLY")
    expect_equal(session$returned()$tickers, "LLY")

    session$setInputs(tickers = c("PFE", "JNJ"))
    expect_equal(session$returned()$tickers, c("PFE", "JNJ"))
  })
})
