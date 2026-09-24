# Setup stocktipr theme and styling

Creates a custom bslib theme with the app's dark "terminal" palette and
typography. Called internally by
[`app_ui()`](https://mjfrigaard.github.io/stocktipr/reference/app_ui.md)
to apply global theming.

## Usage

``` r
stocktipr_theme()
```

## Value

A `bs_theme()` object with custom variables and CSS

## Details

The theme defines a dark, Bloomberg-terminal aesthetic:

- **Palette:** near-black background, amber primary, green/red data
  accents, cyan links

- **Typography:** IBM Plex Mono throughout for a fixed-width terminal
  feel

- **Surfaces:** flat, sharp-cornered panels with thin borders

## Examples

``` r
if (FALSE) { # \dontrun{
theme <- stocktipr_theme()
# Use in app_ui():
# page_sidebar(theme = theme, ...)
} # }
```
