test_that("mod_tooltip bslib wraps the trigger in a popover", {
  tip <- mod_tooltip(shiny::tags$span("Info"), type = "bslib", contents = "Popover body")

  expect_match(as.character(tip), "bslib-popover")
  expect_match(as.character(tip), "Popover body")
})

test_that("mod_tooltip shinyhelper returns a helper tag list", {
  tip <- mod_tooltip(shiny::tags$span("Help"), type = "shinyhelper", contents = c("Line 1", "Line 2"))

  expect_s3_class(tip, "shiny.tag.list")
  expect_match(as.character(tip), "shinyhelper")
})

test_that("mod_tooltip prompter adds a hint class and aria-label", {
  tip <- mod_tooltip(shiny::tags$span("Hover"), type = "prompter", contents = "Hint text", position = "right")
  html <- as.character(tip)

  expect_match(html, "hint--right")
  expect_match(html, 'aria-label="Hint text"', fixed = TRUE)
})

test_that("mod_tooltip shinyalert stores the alert in data attributes", {
  tip <- mod_tooltip(
    shiny::tags$span("Click"),
    type = "shinyalert",
    contents = "Alert body",
    alert_type = "warning",
    title = "Alert title"
  )
  html <- as.character(tip)

  expect_match(html, "sa-trigger")
  expect_match(html, 'data-sa-text="Alert body"', fixed = TRUE)
  expect_match(html, 'data-sa-type="warning"', fixed = TRUE)
  expect_match(html, 'data-sa-title="Alert title"', fixed = TRUE)
})

test_that("mod_tooltip applies size and style to the trigger", {
  html <- as.character(mod_tooltip(type = "bslib", contents = "x", size = "0.85rem", style = "color:red"))

  expect_match(html, "font-size:0.85rem; color:red", fixed = TRUE)
})

test_that("mod_tooltip rejects an unknown type", {
  expect_error(mod_tooltip(type = "invalid", contents = "x"), "should be one of")
})
