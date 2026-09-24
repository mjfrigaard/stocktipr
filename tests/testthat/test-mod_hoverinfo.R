test_that("mod_hoverinfo joins contents into the title attribute", {
  span <- mod_hoverinfo(contents = c("a", "b"), display = "42")

  expect_s3_class(span, "shiny.tag")
  expect_equal(span$name, "span")
  expect_equal(span$attribs$title, "a | b")
  expect_match(as.character(span), ">42</span>", fixed = TRUE)
})

test_that("mod_hoverinfo prefixes named contents with their names", {
  span <- mod_hoverinfo(contents = c(Return = "10%", "note"))

  expect_equal(span$attribs$title, "Return: 10% | note")
})

test_that("mod_hoverinfo applies size and style", {
  span <- mod_hoverinfo(contents = "x", size = "0.8rem", style = "color:red")

  expect_equal(span$attribs$style, "font-size:0.8rem; color:red")
})

test_that("mod_hoverinfo only supports reactable", {
  expect_error(mod_hoverinfo(type = "bslib", contents = "x"))
})
