# Implementation

``` r

library(stocktipr)
#> 
#> Attaching package: 'stocktipr'
#> The following object is masked from 'package:base':
#> 
#>     %||%
```

## Technical Implementation Details

### Shiny Integration

All modules follow the standard Shiny module contract:

1.  **UI functions**: `mod_<name>_ui(id)` returns a valid Shiny tag
    object suitable for embedding in any UI tree
2.  **Server functions**: `mod_<name>_server(id, ...)` wraps its logic
    in `shiny::moduleServer(id, ...)`
3.  **Namespace functions**: `shiny::NS(id)` is called independently
    inside each UI function; `moduleServer()` handles namespacing on the
    server side
4.  **Reactives**: server functions return reactive values/expressions
    directly
    (e.g. [`mod_inputs_server()`](https://mjfrigaard.github.io/stocktipr/reference/mod_inputs_server.md)
    returns a reactive list;
    [`mod_outputs_server()`](https://mjfrigaard.github.io/stocktipr/reference/mod_outputs_server.md)
    returns `perf_r`)

### Data Pipeline Architecture

    mod_inputs_server() → inputs_r (reactive list)
                           ↓
    mod_outputs_server(inputs_r) → prices_r (eventReactive on fetch)
                                     ↓
                                 returns_r (reactive computation)
                                     ↓
                                 perf_r (reactive summary)
                                     ↓
    mod_download_server(inputs_r, perf_r) → handles download

### Logging Architecture

    stocktipr/app                 # App-level events
    ├── stocktipr/inputs        # Input module events
    ├── stocktipr/outputs       # Output module events
    │   ├── stocktipr/tooltip   # Tooltip dispatch
    │   └── stocktipr/hoverinfo # Hover-info rendering
    └── stocktipr/download      # Download module events

`stocktipr` uses the [`logger`](https://daroczig.github.io/logger/)
package for structured, namespace-aware logging throughout the
application. Every log call carries a `namespace` argument identifying
exactly which module or layer emitted the message.

#### Log-level hierarchy

`logger` defines seven levels from most to least verbose:

| Level | Function | When to use |
|----|----|----|
| `TRACE` | `log_trace()` | Fine-grained internal steps (loops, branches) |
| `DEBUG` | `log_debug()` | Per-reactive / per-call diagnostics |
| `INFO` | `log_info()` | Key lifecycle events (session start, fetch, render complete) |
| `SUCCESS` | `log_success()` | Explicit success confirmations |
| `WARN` | `log_warn()` | Recoverable issues (empty ticker list, unexpected input) |
| `ERROR` | `log_error()` | Caught errors before re-throwing |
| `FATAL` | `log_fatal()` | Unrecoverable failures |

The package default threshold is `INFO`: `DEBUG` and `TRACE` lines are
silent unless you explicitly lower the threshold.

#### Namespaces in this package

Every `logger::log_*()` call passes an explicit `namespace` string. The
full set, registered in
[`app_set_log_threshold()`](https://mjfrigaard.github.io/stocktipr/reference/app_set_log_threshold.md),
is:

| Namespace | File | Covers |
|----|----|----|
| `"global"` | — | logger’s built-in global namespace (fallback) |
| `"stocktipr/app"` | `app_ui.R`, `app_server.R` | UI construction, session lifecycle, module wiring |
| `"stocktipr/inputs"` | `mod_inputs.R` | Fetch-button events, reactive inputs list |
| `"stocktipr/outputs"` | `mod_outputs.R` | Price fetch, returns, performance, all render calls |
| `"stocktipr/download"` | `mod_download.R` | Filename generation, report render |
| `"stocktipr/tooltip"` | `mod_tooltip.R` | Tooltip helper dispatch |
| `"stocktipr/hoverinfo"` | `mod_hoverinfo.R` | Hover-span construction |

The `"stocktipr/<module>"` convention means you can silence one noisy
module while keeping the others verbose.

#### `app_set_log_threshold()`

The single entry point for changing thresholds. Called once per session
in
[`app_server()`](https://mjfrigaard.github.io/stocktipr/reference/app_server.md),
it applies the same level to every namespace in the table above:

``` r

app_set_log_threshold <- function(level = logger::INFO) {
  namespaces <- c(
    "global",
    "stocktipr/app",
    "stocktipr/inputs",
    "stocktipr/outputs",
    "stocktipr/download",
    "stocktipr/tooltip",
    "stocktipr/hoverinfo"
  )
  lapply(namespaces, \(ns) logger::log_threshold(level, namespace = ns))
  invisible(level)
}
```

Common threshold recipes:

``` r

# default (production) — INFO and above only
stocktipr::app_set_log_threshold(logger::INFO)

# dev — everything including DEBUG
stocktipr::app_set_log_threshold(logger::DEBUG)

# silent except for warnings and errors
stocktipr::app_set_log_threshold(logger::WARN)
```

You can override individual namespaces after calling
[`app_set_log_threshold()`](https://mjfrigaard.github.io/stocktipr/reference/app_set_log_threshold.md):

``` r

# make the outputs module verbose while keeping everything else at INFO
stocktipr::app_set_log_threshold(logger::INFO)
logger::log_threshold(logger::DEBUG, namespace = "stocktipr/outputs")

# silence the download module entirely
logger::log_threshold(logger::FATAL, namespace = "stocktipr/download")

# read back the current threshold for a namespace
logger::log_threshold(namespace = "stocktipr/outputs")
```

#### `with_logging()`

A `tryCatch` / `withCallingHandlers` wrapper used around expressions
that might warn or error. It logs both with a `context` label, then
re-issues the condition so Shiny and the caller continue to see it
normally:

``` r

with_logging <- function(expr, context = "", ns = "stocktipr/app") {
  tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        logger::log_warn(
          "[{context}] Warning: {conditionMessage(w)}",
          namespace = ns
        )
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      logger::log_error(
        "[{context}] Error: {conditionMessage(e)}",
        namespace = ns
      )
      stop(e)
    }
  )
}
```

It wraps module wiring in
[`app_server()`](https://mjfrigaard.github.io/stocktipr/reference/app_server.md)
and individual output renderers inside module server functions — see
[`?with_logging`](https://mjfrigaard.github.io/stocktipr/reference/with_logging.md)
for the full call sites.

#### Log-level patterns by function

| Function | Namespace | Example events |
|----|----|----|
| [`app_ui()`](https://mjfrigaard.github.io/stocktipr/reference/app_ui.md) / [`app_server()`](https://mjfrigaard.github.io/stocktipr/reference/app_server.md) | `"stocktipr/app"` | Session start/end (`INFO`); warnings/errors from [`with_logging()`](https://mjfrigaard.github.io/stocktipr/reference/with_logging.md) |
| [`mod_inputs_server()`](https://mjfrigaard.github.io/stocktipr/reference/mod_inputs_server.md) | `"stocktipr/inputs"` | Init (`DEBUG`); fetch pressed (`INFO`); no tickers selected (`WARN`) |
| [`mod_outputs_server()`](https://mjfrigaard.github.io/stocktipr/reference/mod_outputs_server.md) | `"stocktipr/outputs"` | Price fetch/returns/summary lifecycle (`INFO`/`DEBUG`); fetch/compute failures (`ERROR`) |
| [`mod_download_server()`](https://mjfrigaard.github.io/stocktipr/reference/mod_download_server.md) | `"stocktipr/download"` | Filename generated, render started/complete (`INFO`); template missing, render failure (`ERROR`) |
| [`mod_hoverinfo()`](https://mjfrigaard.github.io/stocktipr/reference/mod_hoverinfo.md) | `"stocktipr/hoverinfo"` | Span construction (`DEBUG`); build failure (`ERROR`) |

#### Message format

All messages use `logger`’s
[`glue`](https://glue.tidyverse.org/)-interpolation syntax, with a
pipe-separated `key: value` pattern that’s easy to `grep`:

``` r

logger::log_info(
  "Fetching prices | tickers: [{paste(tickers, collapse = ', ')}] | from: {from} | to: {to}",
  namespace = "stocktipr/outputs"
)
# → INFO [2026-04-03 08:00:00] Fetching prices | tickers: [AAPL, MSFT] | from: 2024-01-01 | to: 2024-12-31
```

``` bash
grep "tickers:" app.log
grep "ERROR" app.log
grep "stocktipr/outputs" app.log
```

#### Writing to a file

``` r

# Append all INFO+ messages to a rotating log file
logger::log_appender(
  logger::appender_tee(file = "stocktipr.log"),
  namespace = "stocktipr/app"
)

# Or route a specific namespace to its own file
logger::log_appender(
  logger::appender_file("outputs.log"),
  namespace = "stocktipr/outputs"
)
```

------------------------------------------------------------------------

## Package Configuration

### DESCRIPTION File

Key sections:

- **Package**: `stocktipr`
- **Version**: `0.0.1`
- **Type**: Package with Shiny application
- **Imports**: bslib, shiny, dplyr, tidyquant, tidyfinance, reactable,
  logger, shinyhelper, shinyalert, prompter, bsicons, etc.
- **Suggests**: devtools, knitr
- **VignetteBuilder**: knitr
- **Roxygen**: Configured for Markdown documentation generation

### renv.lock (Dependencies)

Pins exact versions for reproducibility: R 4.6.1, 200+ packages with
specific versions.
