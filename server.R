# server.R

# Definir a função server para a aplicação Shiny
server <- function(input, output) {
  
  # Filtrar dados com base no ano selecionado
  filtered_data <- reactive({
    weather %>% filter(Year == input$year)
  })
  
  
  # Renderizar o gráfico de linha interativo
  output$line_plot <- renderPlotly({
    ggplotly(
      ggplot(filtered_data(), aes(x = Date, y = !!sym(input$variable), color = !!sym(input$variable))) +
        geom_line() +
        labs(title = "Variação ao longo do tempo", x = "Data", y = input$variable) +
        theme_minimal()
    )
  })
  
  # Renderizar o gráfico de dispersão interativo
  output$scatter_plot <- renderPlotly({
    ggplotly(
      ggplot(filtered_data(), aes(x = Date, y = !!sym(input$variable), color = !!sym(input$variable))) +
        geom_point() +
        labs(title = "Dispersão ao longo do tempo", x = "Data", y = input$variable) +
        theme_minimal() +
        scale_color_gradient(low = "blue", high = "red")  # Escolha as cores desejadas
    )
  })
  
  # Renderizar o gráfico de barra interativo
  output$bar_plot <- renderPlotly({
    ggplotly(
      ggplot(filtered_data(), aes(x = factor(Month), y = !!sym(input$variable), fill = factor(Month))) +
        geom_bar(stat = "identity") +
        labs(title = "Variação por Mês", x = "Mês", y = input$variable) +
        theme_minimal()
    )
  })
  
  # Renderizar o gráfico de barras empilhadas interativo
  output$stacked_bar_plot <- renderPlotly({
    # Substitua com os dados e aes apropriados para o gráfico de barras empilhadas
    data_stacked_bar <- weather %>%
      group_by(Month, Year) %>%
      summarise(Value = sum(!!sym(input$variable)))
    
    ggplotly(
      ggplot(data_stacked_bar, aes(x = factor(Month), y = Value, fill = factor(Year))) +
        geom_bar(stat = "identity") +
        labs(title = "Variação por Mês e Ano", x = "Mês", y = input$variable) +
        theme_minimal()
    )
  })
  
  # Renderizar estatísticas mensais fictícias
  output$estatistica_mensal_1 <- renderPlotly({
    # Estatísticas mensais fictícias (substitua com suas próprias estatísticas)
    data <- weather %>%
      group_by(Month) %>%
      summarise(Mean_Temperature = mean(Temperatura))
    
    ggplotly(
      ggplot(data, aes(x = factor(Month), y = Mean_Temperature)) +
        geom_bar(stat = "identity", fill = "skyblue") +
        labs(title = "Média Mensal de Temperatura", x = "Mês", y = "Média de Temperatura") +
        theme_minimal()
    )
  })
  
  output$estatistica_mensal_2 <- renderPlotly({
    # Estatísticas mensais fictícias (substitua com suas próprias estatísticas)
    data <- weather %>%
      group_by(Month) %>%
      summarise(Total_Precipitation = sum(Precipitação))
    
    ggplotly(
      ggplot(data, aes(x = factor(Month), y = Total_Precipitation)) +
        geom_bar(stat = "identity", fill = "lightgreen") +
        labs(title = "Total Mensal de Precipitação", x = "Mês", y = "Total de Precipitação") +
        theme_minimal()
    )
  })
  
  # Renderizar estatísticas anuais fictícias com gráfico térmico
  output$estatistica_anual_1 <- renderPlotly({
    # Estatísticas anuais fictícias (substitua com suas próprias estatísticas)
    data <- weather %>%
      group_by(Year) %>%
      summarise(Mean_Temperature = mean(Temperatura))
    
    ggplotly(
      ggplot(data, aes(x = factor(Year), y = 1, fill = Mean_Temperature)) +
        geom_tile() +
        scale_fill_gradient(low = "skyblue", high = "red") +
        labs(title = "Média Anual de Temperatura", x = "Ano", y = "") +
        theme_minimal()
    )
  })
  
  output$estatistica_anual_2 <- renderPlotly({
    # Estatísticas anuais fictícias (substitua com suas próprias estatísticas)
    data <- weather %>%
      group_by(Year) %>%
      summarise(Total_Precipitation = sum(Precipitação))
    
    ggplotly(
      ggplot(data, aes(x = factor(Year), y = 1, fill = Total_Precipitation)) +
        geom_tile() +
        scale_fill_gradient(low = "lightgreen", high = "darkgreen") +
        labs(title = "Total Anual de Precipitação", x = "Ano", y = "") +
        theme_minimal()
    )
  })
  
  # Exibir informações de texto
  output$info_text <- renderText({
    paste("Variação ao longo do tempo para", input$variable, "no ano", input$year)
  })
} 