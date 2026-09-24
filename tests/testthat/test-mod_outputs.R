test_that("mod_outputs_ui namespaces its outputs", {
  html <- as.character(mod_outputs_ui("myoutputs"))

  for (output_id in c("value_boxes", "tabs", "bslib_boxes", "reactable_perf")) {
    expect_match(html, sprintf("myoutputs-%s", output_id), fixed = TRUE)
  }
})

test_that("mod_outputs_ui contains all five demo tabs", {
  html <- as.character(mod_outputs_ui("outputs"))

  for (tab in c("bslib", "shinyhelper", "prompter", "shinyalert", "reactable")) {
    expect_match(html, sprintf('data-value="%s"', tab), fixed = TRUE)
  }
})

test_that("mod_outputs_server returns a reactive", {
  inputs_r <- shiny::reactive(list(
    tickers = "LLY",
    from = as.Date("2023-01-01"),
    to = as.Date("2023-12-31"),
    vol_window = 30L,
    fetch = 0
  ))

  shiny::testServer(mod_outputs_server, args = list(inputs_r = inputs_r), {
    expect_true(shiny::is.reactive(session$returned))
  })
})
