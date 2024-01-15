# data.R

# Definir uma semente para garantir a reprodutibilidade dos dados fictícios de clima
set.seed(123)

# Criar sequências de datas para os anos 2020, 2021, 2022 e 2024
dates_2020 <- seq(as.Date("2020-01-01"), as.Date("2020-12-31"), by = "day")
dates_2021 <- seq(as.Date("2021-01-01"), as.Date("2021-12-31"), by = "day")
dates_2022 <- seq(as.Date("2022-01-01"), as.Date("2022-12-31"), by = "day")
dates_2024 <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")

# Criar um dataframe chamado "weather" contendo dados fictícios de clima
weather <- data.frame(
  Date = c(dates_2020, dates_2021, dates_2022, dates_2024),  # Coluna de datas
  Year = c(rep(2020, length(dates_2020)), rep(2021, length(dates_2021)), rep(2022, length(dates_2022)), rep(2024, length(dates_2024))),  # Coluna de anos
  Month = lubridate::month(c(dates_2020, dates_2021, dates_2022, dates_2024)),  # Coluna de meses usando a biblioteca lubridate
  Temperatura = rnorm(length(c(dates_2020, dates_2021, dates_2022, dates_2024)), mean = 25, sd = 5),  # Coluna de temperaturas geradas aleatoriamente
  Precipitação = rpois(length(c(dates_2020, dates_2021, dates_2022, dates_2024)), lambda = 5)  # Coluna de precipitação gerada aleatoriamente
) 