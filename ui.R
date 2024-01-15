# ui.R

# Carregar bibliotecas necessárias
library(shinydashboard)
library(ggplot2)
library(plotly)

# Carregar os dados do arquivo data.R
source("data.R")

# Definir o layout da interface Shiny
ui <- dashboardPage(
  
  # Cabeçalho do painel de controle
  dashboardHeader(
    title = tags$span(
      HTML('<i class="fas fa-cloud" style="padding-right: 10px;"></i>'),
      "Análise de Clima"
    )
  ),
  
  # Barra lateral do painel de controle
  dashboardSidebar(
    sidebarMenu(
      menuItem("Gráfico de Linha", tabName = "linha", icon = icon("chart-line")),
      menuItem("Gráfico de Coluna", tabName = "barra", icon = icon("signal")),
      menuItem("Estatísticas Mensais", tabName = "estatisticas_mensais", icon = icon("folder-open")),
      menuItem("Estatísticas Anuais", tabName = "estatisticas_anuais", icon = icon("chart-bar"))
    )
  ),
  
  # Corpo do painel de controle com abas
  dashboardBody(
    tabItems(
      # Aba "linha"
      tabItem(tabName = "linha",
              fluidRow(
                # Seletor de variável
                box(width = 2,
                    selectInput(inputId = "variable", label = "Selecionar Variável", choices = c("Temperatura", "Precipitação"), selected = "Temperatura")),
                
                # Filtro de ano
                box(width = 2,
                    sliderInput(inputId = "year", label = "Selecionar Ano", min = min(weather$Year), max = max(weather$Year), value = min(weather$Year), step = 1)),
              ),
              
              # Nova linha para o gráfico
              fluidRow(
                # Box para conter o gráfico e informações
                box(
                  plotlyOutput(outputId = "line_plot"),
                  textOutput(outputId = "info_text")
                ),
                box(
                  width = 6,
                  plotlyOutput(outputId = "scatter_plot")
                )
              )
      ),
      
      # Aba "barra"
      tabItem(tabName = "barra",
              fluidRow(
                # Seletor de variável
                box(width = 2,
                    selectInput(inputId = "variable", label = "Selecionar Variável", choices = c("Temperatura", "Precipitação"), selected = "Temperatura")),
                
                # Filtro de ano
                box(width = 2,
                    sliderInput(inputId = "year", label = "Selecionar Ano", min = min(weather$Year), max = max(weather$Year), value = min(weather$Year), step = 1))
              ),
              
              # Gráfico de barra interativo
              fluidRow(
                box(
                  plotlyOutput(outputId = "bar_plot")
                ),
                # Novo box para conter o gráfico
                box(
                  plotlyOutput(outputId = "stacked_bar_plot")
                )
              )
      ),
      
      # Aba "estatisticas_mensais"
      tabItem(
        tabName = "estatisticas_mensais",
        fluidRow(
          # Inserir elementos para exibir estatísticas mensais
          box(
            plotlyOutput(outputId = "estatistica_mensal_1")),
          box(
            plotlyOutput(outputId = "estatistica_mensal_2"))
        )
      ),
      
      # Aba "estatisticas_anuais"
      tabItem(
        tabName = "estatisticas_anuais",
        fluidRow(
          # Inserir elementos para exibir estatísticas anuais
          box(
            plotlyOutput(outputId = "estatistica_anual_1")),
          box(
            plotlyOutput(outputId = "estatistica_anual_2"))
        )
      )
    )
  )
)