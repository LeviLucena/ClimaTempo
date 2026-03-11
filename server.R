# server.R
library(dplyr)
library(lubridate)
library(shiny)

# ── Visual maps ───────────────────────────────────────────────────────────────

ICON_MAP <- c(
  "Ensolarado"    = "fa-sun",        "Noite limpa"   = "fa-moon",
  "Parc. nublado" = "fa-cloud-sun",  "Nublado"       = "fa-cloud",
  "Chuva"         = "fa-cloud-rain", "Chuva forte"   = "fa-cloud-showers-heavy",
  "Tempestade"    = "fa-cloud-bolt", "Neve"          = "fa-snowflake"
)
COLOR_MAP <- c(
  "Ensolarado"    = "#FFD700", "Noite limpa"   = "#a0b4c8",
  "Parc. nublado" = "#FFA500", "Nublado"       = "#8a9bb0",
  "Chuva"         = "#4fa3e0", "Chuva forte"   = "#2d6fa3",
  "Tempestade"    = "#9b59b6", "Neve"          = "#AED6F1"
)
BG_MAP <- c(
  "Ensolarado"    = "linear-gradient(135deg,#1a78c2,#56b4d3)",
  "Noite limpa"   = "linear-gradient(135deg,#0d1b2a,#1c3a57)",
  "Parc. nublado" = "linear-gradient(135deg,#4a6fa5,#7faacc)",
  "Nublado"       = "linear-gradient(135deg,#3d4f60,#5a7080)",
  "Chuva"         = "linear-gradient(135deg,#2d3748,#3d5a72)",
  "Chuva forte"   = "linear-gradient(135deg,#1a252f,#2c3e50)",
  "Tempestade"    = "linear-gradient(135deg,#0d1117,#2c1654)",
  "Neve"          = "linear-gradient(135deg,#8ab8d4,#c8dce8)"
)

DIAS_PT  <- c("Dom","Seg","Ter","Qua","Qui","Sex","Sab")
MESES_PT <- c("Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez")

SUNRISE_H <- c("Sao Paulo"=6, "Rio de Janeiro"=5, "Curitiba"=6, "Manaus"=6, "Florianopolis"=6)
SUNSET_H  <- c("Sao Paulo"=18, "Rio de Janeiro"=18, "Curitiba"=18, "Manaus"=18, "Florianopolis"=19)

# Moon phase emoji (HTML entities — safe across encodings)
MOON_EMOJI <- c(
  "Lua Nova"         = "&#127761;", "Crescente"     = "&#127762;",
  "Quarto Crescente" = "&#127763;", "Gibosa Cresc." = "&#127764;",
  "Lua Cheia"        = "&#127765;", "Gibosa Ming."  = "&#127766;",
  "Quarto Ming."     = "&#127767;", "Minguante"     = "&#127768;"
)

# ── Helper functions ──────────────────────────────────────────────────────────

get_icon  <- function(c) { v <- ICON_MAP[c];  if (is.na(v)) "fa-cloud"  else v }
get_color <- function(c) { v <- COLOR_MAP[c]; if (is.na(v)) "#8a9bb0"   else v }
get_bg    <- function(c) { v <- BG_MAP[c];    if (is.na(v)) BG_MAP["Nublado"] else v }

wi <- function(cond, size = "1.4rem") {
  tags$i(class = paste("fa-solid", get_icon(cond)),
         style = paste0("color:", get_color(cond), "; font-size:", size))
}

metric_card <- function(icon_fa, icon_color, value, label, sub = NULL) {
  div(class = "ct-metric-card",
    div(class = "ct-metric-icon",
      tags$i(class = paste("fa-solid", icon_fa), style = paste0("color:", icon_color))
    ),
    div(class = "ct-metric-value", value),
    div(class = "ct-metric-label", label),
    if (!is.null(sub)) div(class = "ct-metric-sub", sub)
  )
}

moon_phase_info <- function(date) {
  days <- as.numeric(as.Date(date) - as.Date("2000-01-06"))
  frac <- (days %% 29.53059) / 29.53059
  idx  <- floor(frac * 8) + 1
  idx  <- min(max(idx, 1), 8)
  nomes  <- names(MOON_EMOJI)
  list(nome = nomes[idx], emoji = MOON_EMOJI[nomes[idx]], illumination = round(abs(sin(frac * pi)) * 100))
}

sun_arc_svg <- function(sunrise_h, sunset_h, current_h) {
  pos   <- max(0, min(1, (current_h - sunrise_h) / (sunset_h - sunrise_h)))
  theta <- pi * (1 - pos)
  sun_x <- round(120 + 60 * cos(theta), 1)
  sun_y <- round(70  - 60 * sin(theta), 1)
  is_day <- current_h > sunrise_h && current_h < sunset_h
  sun_fill <- if (is_day) "#FFD700" else "rgba(200,220,255,0.4)"
  sun_glow  <- if (is_day) "drop-shadow(0 0 6px rgba(255,210,0,0.8))" else "none"

  HTML(paste0(
    '<svg viewBox="0 0 240 85" style="width:100%;max-width:320px;display:block;margin:0 auto" xmlns="http://www.w3.org/2000/svg">',
    '<path d="M 60 72 A 60 60 0 0 1 180 72" fill="none" stroke="rgba(255,255,255,.12)" stroke-width="2" stroke-dasharray="4 3"/>',
    if (pos > 0.01 && pos < 0.99)
      paste0('<path d="M 60 72 A 60 60 0 0 1 ', sun_x, ' ', sun_y,
             '" fill="none" stroke="rgba(255,200,0,.65)" stroke-width="2.5" stroke-linecap="round"/>'),
    '<line x1="20" y1="72" x2="220" y2="72" stroke="rgba(255,255,255,.1)" stroke-width="1"/>',
    '<circle cx="60"  cy="72" r="3" fill="rgba(255,200,0,.35)"/>',
    '<circle cx="180" cy="72" r="3" fill="rgba(255,150,0,.35)"/>',
    '<circle cx="', sun_x, '" cy="', sun_y, '" r="8" fill="', sun_fill,
    '" style="filter:', sun_glow, '"/>',
    '<text x="60"  y="82" font-size="8" fill="rgba(255,255,255,.4)" text-anchor="middle">',
    sprintf("%02d:00", sunrise_h), '</text>',
    '<text x="180" y="82" font-size="8" fill="rgba(255,255,255,.4)" text-anchor="middle">',
    sprintf("%02d:00", sunset_h), '</text>',
    '</svg>'
  ))
}

aqi_label <- function(v) {
  if (v <= 50) "Bom" else if (v <= 100) "Moderado" else
  if (v <= 150) "Sensivel" else if (v <= 200) "Ruim" else "Perigoso"
}
aqi_color <- function(v) {
  if (v <= 50) "#4CAF50" else if (v <= 100) "#FFC107" else
  if (v <= 150) "#FF9800" else if (v <= 200) "#f44336" else "#9b59b6"
}
uv_label <- function(v) {
  if (v <= 2) "Baixo" else if (v <= 5) "Moderado" else if (v <= 7) "Alto" else "Muito alto"
}
uv_color <- function(v) {
  if (v <= 2) "#4CAF50" else if (v <= 5) "#FFC107" else if (v <= 7) "#FF9800" else "#f44336"
}

generate_alerts <- function(d) {
  alerts <- list()
  if (d$Condicao == "Tempestade")
    alerts[[length(alerts)+1]] <- list(icon="fa-bolt",     color="#a29bfe", msg="Tempestade severa na area")
  if (d$UV >= 8)
    alerts[[length(alerts)+1]] <- list(icon="fa-sun",      color="#fdcb6e", msg=paste0("Indice UV extremo: ", d$UV))
  if (d$Temp < 2)
    alerts[[length(alerts)+1]] <- list(icon="fa-snowflake",color="#74b9ff", msg=paste0("Risco de gelo — ", d$Temp, "°C"))
  if (d$VentoVel > 60)
    alerts[[length(alerts)+1]] <- list(icon="fa-wind",     color="#fd79a8", msg=paste0("Vendaval: ", d$VentoVel, " km/h"))
  alerts
}

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # Auto-refresh every 5 minutes
  timer <- reactiveTimer(300000)

  sel_date <- reactive({
    if (is.null(input$data_sel)) Sys.Date() else as.Date(input$data_sel)
  })

  now_data <- reactive({
    timer()
    d <- sel_date()
    if (d == Sys.Date()) {
      weather %>%
        filter(Cidade == input$cidade, DateTime <= Sys.time()) %>%
        slice_tail(n = 1)
    } else {
      weather %>%
        filter(Cidade == input$cidade, Date == d) %>%
        slice_min(abs(Hora - 12), n = 1, with_ties = FALSE)
    }
  })

  today_data <- reactive({
    timer()
    weather %>% filter(Cidade == input$cidade, Date == sel_date())
  })

  hourly_data <- reactive({
    timer()
    d <- sel_date()
    if (d == Sys.Date()) {
      weather %>%
        filter(Cidade == input$cidade, DateTime >= floor_date(Sys.time(), "hour")) %>%
        head(24)
    } else {
      weather %>%
        filter(Cidade == input$cidade, Date == d) %>%
        arrange(Hora) %>%
        head(24)
    }
  })

  daily_data <- reactive({
    weather %>%
      filter(Cidade == input$cidade, Date >= sel_date()) %>%
      group_by(Date) %>%
      summarise(
        TempMax  = max(Temp), TempMin = min(Temp),
        Precip   = sum(Precip),
        Condicao = names(which.max(table(Condicao))),
        .groups  = "drop"
      ) %>%
      head(7)
  })

  # ── Clock ──────────────────────────────────────────────────────────────────
  output$relogio <- renderText({
    invalidateLater(60000)
    m <- as.integer(format(Sys.Date(), "%m"))
    paste0(format(Sys.Date(), "%d "), MESES_PT[m], format(Sys.time(), "  %H:%M"))
  })

  # ── Alert banner ───────────────────────────────────────────────────────────
  output$alert_banner <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    alerts <- generate_alerts(d)
    req(length(alerts) > 0)
    div(class = "ct-alert-banner",
      tagList(lapply(alerts, function(a) {
        div(
          tags$i(class = paste("fa-solid", a$icon), style = paste0("color:", a$color)),
          paste0(" ", a$msg)
        )
      }))
    )
  })

  # Toast on severe weather (once per city change)
  observeEvent(input$cidade, {
    d <- isolate(now_data())
    req(nrow(d) > 0)
    alerts <- generate_alerts(d)
    if (length(alerts) > 0) {
      a <- alerts[[1]]
      session$sendCustomMessage("showToast", list(
        msg  = paste0('<i class="fa-solid ', a$icon, '" style="color:', a$color, '"></i> ', a$msg),
        type = "danger"
      ))
    }
  }, ignoreInit = TRUE)

  # ── Hero ───────────────────────────────────────────────────────────────────
  output$hero <- renderUI({
    d  <- now_data();  req(nrow(d) > 0)
    td <- today_data()
    cond <- d$Condicao

    div(class = "ct-hero",
      `data-condition` = cond,
      style = paste0("background:", get_bg(cond)),
      # Left
      div(class = "ct-hero-left",
        div(class = "ct-hero-temp",  paste0(d$Temp, "°C")),
        div(class = "ct-hero-cond",  cond),
        div(class = "ct-hero-feels",
          tags$i(class = "fa-solid fa-temperature-half"),
          paste0(" Sensacao: ", d$Sensacao, "°C"))
      ),
      # Centre
      div(class = "ct-hero-icon", wi(cond, "6rem")),
      # Right
      div(class = "ct-hero-right",
        div(class = "ct-hero-city",
          tags$i(class = "fa-solid fa-location-dot"), " ", input$cidade),
        div(class = "ct-hero-minmax",
          tags$i(class = "fa-solid fa-arrow-up",   style = "color:#ff6b6b"),
          paste0(" ", max(td$Temp, na.rm = TRUE), "°  "),
          tags$i(class = "fa-solid fa-arrow-down", style = "color:#74b9ff"),
          paste0(" ", min(td$Temp, na.rm = TRUE), "°")),
        div(class = "ct-hero-nuvem",
          tags$i(class = "fa-solid fa-cloud"),
          paste0("  ", d$Nuvem, "% nuvens")),
        div(class = "ct-hero-prec",
          tags$i(class = "fa-solid fa-umbrella"),
          paste0("  ", sum(td$Precip, na.rm = TRUE), " mm hoje"))
      )
    )
  })

  # ── Metric cards ───────────────────────────────────────────────────────────
  output$m_umidade  <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    metric_card("fa-droplet", "#4fa3e0", paste0(d$Umidade, "%"), "Umidade")
  })
  output$m_orvalho  <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    metric_card("fa-temperature-low", "#74b9ff", paste0(d$PontoOrvalho, "°C"), "Pto. Orvalho")
  })
  output$m_vento    <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    metric_card("fa-wind", "#a8d8ea", paste0(d$VentoVel, " km/h"), "Vento", d$VentoDir)
  })
  output$m_chuva    <- renderUI({
    d  <- now_data(); td <- today_data(); req(nrow(d) > 0)
    total <- sum(td$Precip, na.rm = TRUE)
    metric_card("fa-cloud-rain", "#56b4d3", paste0(total, " mm"), "Chuva hoje",
                if (total == 0) "Sem chuva" else paste0(d$Precip, " mm/h"))
  })
  output$m_pressao  <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    metric_card("fa-gauge", "#f39c12", paste0(d$Pressao, " hPa"), "Pressao")
  })
  output$m_uv       <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    metric_card("fa-sun", uv_color(d$UV), paste0("UV ", d$UV), "Indice UV", uv_label(d$UV))
  })
  output$m_visib    <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    metric_card("fa-eye", "#9b59b6", paste0(d$Visib, " km"), "Visibilidade")
  })

  # ── Sunrise arc ────────────────────────────────────────────────────────────
  output$sunrise_arc <- renderUI({
    d        <- now_data(); req(nrow(d) > 0)
    sr       <- SUNRISE_H[[input$cidade]]
    ss       <- SUNSET_H[[input$cidade]]
    cur_h    <- if (sel_date() == Sys.Date()) as.integer(format(Sys.time(), "%H")) else 12
    is_day   <- cur_h > sr && cur_h < ss
    mins_left <- if (is_day) paste0(ss - cur_h, "h para o por do sol") else "Noite"

    div(class = "ct-sun-card",
      div(class = "ct-sun-title",
        tags$i(class = "fa-solid fa-sun", style = "color:#FFD700"), " Nascer / Por do Sol"
      ),
      sun_arc_svg(sr, ss, cur_h),
      div(class = "ct-sun-info",
        div(tags$i(class = "fa-solid fa-sunrise", style = "color:#FFA500"),
            paste0(" Nasce: ", sprintf("%02d:00", sr))),
        div(tags$i(class = "fa-solid fa-sunset",  style = "color:#ff6b6b"),
            paste0(" Poe: ",   sprintf("%02d:00", ss))),
        div(style = "opacity:.6; font-size:.8rem; margin-top:.3rem", mins_left)
      )
    )
  })

  # ── Moon phase ─────────────────────────────────────────────────────────────
  output$moon_card <- renderUI({
    moon <- moon_phase_info(sel_date())
    div(class = "ct-sun-card",
      div(class = "ct-sun-title",
        tags$i(class = "fa-solid fa-moon", style = "color:#a0b4c8"), " Fase da Lua"
      ),
      div(class = "ct-moon-emoji", HTML(moon$emoji)),
      div(class = "ct-moon-name", moon$nome),
      div(class = "ct-moon-illum",
        div(class = "ct-moon-bar-wrap",
          div(class = "ct-moon-bar-fill",
              style = paste0("width:", moon$illumination, "%"))
        ),
        div(style = "font-size:.75rem; opacity:.5; margin-top:.25rem",
            paste0(moon$illumination, "% iluminada"))
      )
    )
  })

  # ── AQI card ───────────────────────────────────────────────────────────────
  output$card_aqi <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    pct <- min(100, d$IQA / 3)
    div(class = "ct-sun-card",
      div(class = "ct-sun-title",
        tags$i(class = "fa-solid fa-leaf", style = paste0("color:", aqi_color(d$IQA))),
        " Qualidade do Ar"
      ),
      div(class = "ct-aqi-value",
        style = paste0("color:", aqi_color(d$IQA)),
        paste0("IQA ", d$IQA)
      ),
      div(class = "ct-aqi-label", aqi_label(d$IQA)),
      div(class = "ct-aqi-bar-track",
        div(class = "ct-aqi-bar-fill", style = paste0("width:", pct, "%"))
      )
    )
  })

  # ── Hourly forecast ────────────────────────────────────────────────────────
  output$hourly <- renderUI({
    h    <- hourly_data(); req(nrow(h) > 0)
    now_h <- as.integer(format(Sys.time(), "%H"))

    cards <- lapply(seq_len(nrow(h)), function(i) {
      r      <- h[i, ]
      is_now <- r$Hora == now_h && r$Date == Sys.Date()
      div(class = paste0("ct-hour-card", if (is_now) " now" else ""),
        div(class = "ct-hour-time",  if (is_now) "Agora" else paste0(sprintf("%02d", r$Hora), "h")),
        div(class = "ct-hour-icon",  wi(r$Condicao, "1.4rem")),
        div(class = "ct-hour-temp",  paste0(r$Temp, "°")),
        div(class = "ct-hour-prec",
            if (r$Precip > 0) paste0(r$Precip, " mm")
            else if (r$Neve > 0) paste0(r$Neve, " cm") else "")
      )
    })
    div(style = "display:flex; gap:.6rem", tagList(cards))
  })

  # ── Weekly temperature bars ────────────────────────────────────────────────
  output$weekly_bars <- renderUI({
    d <- daily_data(); req(nrow(d) > 0)
    gmin <- min(d$TempMin) - 1
    gmax <- max(d$TempMax) + 1
    rng  <- gmax - gmin

    rows <- lapply(seq_len(nrow(d)), function(i) {
      r       <- d[i, ]
      wd      <- DIAS_PT[as.integer(format(r$Date, "%w")) + 1]
      is_today <- r$Date == Sys.Date()
      left_pct  <- round((r$TempMin - gmin) / rng * 100, 1)
      width_pct <- round((r$TempMax - r$TempMin) / rng * 100, 1)

      div(class = "ct-bar-row",
        div(class = "ct-bar-day",  if (is_today) "Hoje" else wd),
        div(class = "ct-bar-icon", wi(r$Condicao, ".95rem")),
        div(class = "ct-bar-min",  paste0(round(r$TempMin), "°")),
        div(class = "ct-bar-track",
          div(class = "ct-bar-fill",
              style = paste0("left:", left_pct, "%; width:", width_pct, "%;"))
        ),
        div(class = "ct-bar-max", paste0(round(r$TempMax), "°")),
        if (r$Precip > 0)
          div(class = "ct-bar-prec",
            tags$i(class = "fa-solid fa-droplet", style = "font-size:.65rem; color:#56b4d3"),
            paste0(" ", round(r$Precip), "mm"))
        else div(class = "ct-bar-prec", "")
      )
    })
    div(class = "ct-bar-list", tagList(rows))
  })

  # ── Special cards ──────────────────────────────────────────────────────────
  output$card_mar <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    cond_mar <- if (d$Onda < 0.5) "Calmo" else if (d$Onda < 1.25) "Ondulado" else
                if (d$Onda < 2.5) "Agitado" else "Muito agitado"
    div(class = "ct-special-card",
      div(class = "ct-special-title",
        tags$i(class = "fa-solid fa-water", style = "color:#56b4d3"), " Condicoes do Mar"),
      div(class = "ct-special-value", paste0(d$Onda, " m")),
      div(class = "ct-special-sub", "altura das ondas"),
      tags$hr(class = "ct-divider"),
      div(class = "ct-special-detail",
        div(tags$i(class = "fa-solid fa-thermometer-half", style = "color:#ff6b6b"),
            paste0(" Temp. do mar: ", d$TempMar, "°C")),
        div(tags$i(class = "fa-solid fa-flag", style = "color:#fdcb6e"),
            paste0(" ", cond_mar))
      )
    )
  })

  output$card_vento <- renderUI({
    d <- now_data(); req(nrow(d) > 0)
    deg <- switch(d$VentoDir,
      "N"=0,"NE"=45,"L"=90,"SE"=135,"S"=180,"SO"=225,"O"=270,"NO"=315, 0)
    div(class = "ct-special-card",
      div(class = "ct-special-title",
        tags$i(class = "fa-solid fa-wind", style = "color:#a8d8ea"), " Vento"),
      div(class = "ct-special-value", paste0(d$VentoVel, " km/h")),
      div(class = "ct-special-sub", "velocidade atual"),
      tags$hr(class = "ct-divider"),
      div(class = "ct-wind-rose",
        tags$i(class = "fa-solid fa-location-arrow",
               style = paste0("color:#56b4d3; font-size:2rem; display:inline-block; transform:rotate(",
                              deg, "deg)")),
        div(
          div(style = "font-size:1.1rem; font-weight:600", d$VentoDir),
          div(style = "font-size:.75rem; opacity:.5", "direcao"),
          div(style = "font-size:.85rem; margin-top:.4rem",
            tags$i(class = "fa-solid fa-bolt", style = "color:#fdcb6e"),
            paste0(" Rajadas: ", round(d$VentoVel * 1.4), " km/h"))
        )
      )
    )
  })

  output$card_neve <- renderUI({
    d   <- now_data();  req(nrow(d) > 0)
    td  <- today_data()
    neve_total <- sum(td$Neve, na.rm = TRUE)
    temp_min   <- min(td$Temp, na.rm = TRUE)
    alerta <- if (temp_min < 0) "Risco de gelo na pista" else
              if (temp_min < 5) "Frio intenso" else "Sem risco de neve"
    div(class = "ct-special-card",
      div(class = "ct-special-title",
        tags$i(class = "fa-solid fa-snowflake", style = "color:#AED6F1"), " Neve e Gelo"),
      div(class = "ct-special-value", paste0(neve_total, " cm")),
      div(class = "ct-special-sub", "neve acumulada hoje"),
      tags$hr(class = "ct-divider"),
      div(class = "ct-special-detail",
        div(tags$i(class = "fa-solid fa-arrow-down", style = "color:#74b9ff"),
            paste0(" Temp. min: ", temp_min, "°C")),
        div(tags$i(class = "fa-solid fa-triangle-exclamation", style = "color:#fdcb6e"),
            paste0(" ", alerta))
      )
    )
  })

  # ── Comparison panel ────────────────────────────────────────────────────────
  output$comp_panel <- renderUI({
    req(input$modo_comp)
    cards <- lapply(CIDADES, function(cidade) {
      row <- weather %>%
        filter(Cidade == cidade) %>%
        { if (sel_date() == Sys.Date())
            filter(., DateTime <= Sys.time()) %>% slice_tail(n = 1)
          else
            filter(., Date == sel_date()) %>%
            slice_min(abs(Hora - 12), n = 1, with_ties = FALSE) }
      req(nrow(row) > 0)

      is_sel <- cidade == input$cidade
      div(class = paste0("ct-comp-card", if (is_sel) " selected" else ""),
        div(class = "ct-comp-city", cidade),
        div(class = "ct-comp-icon", wi(row$Condicao, "2.5rem")),
        div(class = "ct-comp-temp", paste0(row$Temp, "°")),
        div(class = "ct-comp-cond", row$Condicao),
        tags$hr(class = "ct-divider"),
        div(class = "ct-comp-metrics",
          div(tags$i(class = "fa-solid fa-droplet",   style = "color:#4fa3e0"),
              paste0(" ", row$Umidade, "%")),
          div(tags$i(class = "fa-solid fa-wind",      style = "color:#a8d8ea"),
              paste0(" ", row$VentoVel, " km/h")),
          div(tags$i(class = "fa-solid fa-cloud-rain",style = "color:#56b4d3"),
              paste0(" ", row$Precip, " mm")),
          div(tags$i(class = "fa-solid fa-sun",       style = paste0("color:", uv_color(row$UV))),
              paste0(" UV ", row$UV))
        )
      )
    })
    div(class = "ct-comp-row", tagList(cards))
  })

  # ── Download CSV ───────────────────────────────────────────────────────────
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0(gsub(" ", "_", input$cidade), "_", sel_date(), ".csv")
    },
    content = function(file) {
      d <- weather %>% filter(Cidade == input$cidade, Date == sel_date())
      write.csv(d, file, row.names = FALSE)
    }
  )
}
