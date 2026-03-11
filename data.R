# data.R
library(lubridate)
library(dplyr)

set.seed(42)

CIDADES    <- c("Sao Paulo", "Rio de Janeiro", "Curitiba", "Manaus", "Florianopolis")
BASE_TEMP  <- c("Sao Paulo"=22, "Rio de Janeiro"=29, "Curitiba"=15, "Manaus"=32, "Florianopolis"=24)
PROB_CHUVA <- c("Sao Paulo"=.25, "Rio de Janeiro"=.30, "Curitiba"=.22, "Manaus"=.45, "Florianopolis"=.23)

start_dt <- as.POSIXct(paste(Sys.Date() - 3, "00:00:00"))
end_dt   <- as.POSIXct(paste(Sys.Date() + 7, "23:00:00"))
horas    <- seq(start_dt, end_dt, by = "hour")
n        <- length(horas)

gerar_cidade <- function(cidade) {
  bt <- BASE_TEMP[[cidade]]
  pc <- PROB_CHUVA[[cidade]]
  h  <- as.integer(format(horas, "%H"))

  temp      <- round(bt + 6 * sin((h - 6) * pi / 12) + rnorm(n, 0, 1.2), 1)
  sensacao  <- round(temp - abs(rnorm(n, 2, 1)), 1)
  umidade   <- round(pmax(35, pmin(99, 72 - (temp - bt) * 1.3 + rnorm(n, 0, 5))))
  vento_vel <- round(pmax(0, abs(rnorm(n, 18, 9))), 1)
  vento_dir <- sample(c("N","NE","L","SE","S","SO","O","NO"), n, replace = TRUE)
  precip    <- round(ifelse(runif(n) < pc & umidade > 65, rpois(n, 4), 0), 1)
  neve      <- round(ifelse(temp < 4, rpois(n, 1), 0), 1)
  nuvem     <- round(pmax(5, pmin(100, 60 * (precip > 0) + umidade / 2 + rnorm(n, 0, 12))))
  uv        <- round(pmax(0, pmin(11, (1 - nuvem/100) * 9 * pmax(0, sin((h - 6) * pi / 12)))))
  visib     <- round(pmax(0.3, pmin(20, 18 - nuvem/12 - precip * 0.8 + rnorm(n, 0, 1))), 1)
  pressao   <- round(1013 + cumsum(rnorm(n, 0, 0.2)))
  onda      <- round(pmax(0.2, 0.8 + vento_vel / 25 + rnorm(n, 0, 0.3)), 1)
  temp_mar  <- round(bt - 4 + rnorm(n, 0, 0.4), 1)

  # Ponto de orvalho (formula de Magnus simplificada)
  ponto_orvalho <- round(temp - ((100 - umidade) / 5), 1)

  # IQA — Indice de Qualidade do Ar (sintetico)
  iqa <- round(pmax(0, pmin(300, 40 + abs(rnorm(n, 0, 20)) + precip * (-4) + nuvem * 0.2)))

  condicao <- case_when(
    neve > 0         ~ "Neve",
    precip > 8       ~ "Tempestade",
    precip > 2       ~ "Chuva forte",
    precip > 0       ~ "Chuva",
    nuvem > 80       ~ "Nublado",
    nuvem > 40       ~ "Parc. nublado",
    h >= 6 & h < 20  ~ "Ensolarado",
    TRUE             ~ "Noite limpa"
  )

  data.frame(
    DateTime     = horas, Date = as.Date(horas), Hora = h,
    Cidade       = cidade, Temp = temp, Sensacao = sensacao,
    Umidade      = umidade, VentoVel = vento_vel, VentoDir = vento_dir,
    Precip       = precip, Neve = neve, Nuvem = nuvem,
    Condicao     = condicao, UV = uv, Visib = visib,
    Pressao      = pressao, Onda = onda, TempMar = temp_mar,
    PontoOrvalho = ponto_orvalho, IQA = iqa,
    stringsAsFactors = FALSE
  )
}

weather <- do.call(rbind, lapply(CIDADES, gerar_cidade))
rownames(weather) <- NULL
