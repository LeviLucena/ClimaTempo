# ui.R
library(shiny)
library(bslib)

source("data.R")

ui <- page_fluid(
  title = "ClimaTempo",
  theme = bs_theme(
    version = 5,
    bg = "#0f1923", fg = "#ffffff",
    primary = "#56b4d3",
    border_radius = "12px",
    "font-size-base" = "0.95rem"
  ),
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "stylesheet", href = "style.css"),
    tags$link(
      rel  = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"
    ),
    tags$script(src = "weather.js")
  ),

  # ── Header ────────────────────────────────────────────────────────────────
  div(class = "ct-header",
    div(class = "ct-brand",
      tags$i(class = "fa-solid fa-cloud-sun"),
      span("ClimaTempo")
    ),
    div(class = "ct-controls",
      selectInput("cidade", NULL, choices = CIDADES, width = "190px"),
      dateInput("data_sel", NULL,
                value = Sys.Date(),
                min   = Sys.Date() - 3,
                max   = Sys.Date() + 7,
                width = "155px",
                format = "dd/mm/yy",
                language = "pt-BR"),
      checkboxInput("modo_comp", tagList(
        tags$i(class = "fa-solid fa-city"), " Comparar"
      ), value = FALSE),
      downloadButton("download_csv", "",
                     icon  = icon("download"),
                     class = "ct-icon-btn"),
      actionButton("toggle_theme", "",
                   icon  = icon("circle-half-stroke"),
                   class = "ct-icon-btn btn-sm"),
      div(class = "ct-clock", textOutput("relogio", inline = TRUE))
    )
  ),

  # ── Alert banner (shown only on severe conditions) ────────────────────────
  uiOutput("alert_banner"),

  # ── Main view (single city) ───────────────────────────────────────────────
  conditionalPanel("!input.modo_comp",

    # Hero
    uiOutput("hero"),

    # 7 metric cards
    div(class = "ct-metrics",
      uiOutput("m_umidade"),
      uiOutput("m_orvalho"),
      uiOutput("m_vento"),
      uiOutput("m_chuva"),
      uiOutput("m_pressao"),
      uiOutput("m_uv"),
      uiOutput("m_visib")
    ),

    # Sun arc + Moon phase + AQI row
    div(class = "ct-section-title",
      tags$i(class = "fa-solid fa-sun"), " Sol, Lua e Qualidade do Ar"
    ),
    div(class = "ct-sun-row",
      uiOutput("sunrise_arc"),
      uiOutput("moon_card"),
      uiOutput("card_aqi")
    ),

    # Hourly
    div(class = "ct-section-title",
      tags$i(class = "fa-solid fa-clock"), " Proximas 24 horas"
    ),
    div(class = "ct-hourly-wrap", uiOutput("hourly")),

    # Weekly temperature bars
    div(class = "ct-section-title",
      tags$i(class = "fa-solid fa-calendar-week"), " Temperatura semanal"
    ),
    div(class = "ct-weekly-wrap", uiOutput("weekly_bars")),

    # Special cards
    div(class = "ct-section-title",
      tags$i(class = "fa-solid fa-water"), " Condicoes especiais"
    ),
    div(class = "ct-special-row",
      uiOutput("card_mar"),
      uiOutput("card_vento"),
      uiOutput("card_neve")
    )
  ),

  # ── Comparison panel ──────────────────────────────────────────────────────
  conditionalPanel("input.modo_comp",
    div(class = "ct-section-title", style = "padding-top:.5rem",
      tags$i(class = "fa-solid fa-city"), " Comparativo de cidades"
    ),
    uiOutput("comp_panel")
  ),

  div(style = "height:2rem")
)
