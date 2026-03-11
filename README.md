# ClimaTempo

Dashboard meteorológico interativo desenvolvido em **R + Shiny**, com visual inspirado em aplicativos de clima profissionais. Exibe condições em tempo real (fictícias), previsão horária, previsão semanal, qualidade do ar, condições do mar, fase da lua, arco solar e muito mais — tudo sem gráficos tradicionais, construído inteiramente com HTML, CSS e SVG.

---

## Funcionalidades

### Painel principal
| Recurso | Descrição |
|---|---|
| **Hero dinâmico** | Temperatura, sensação térmica, condição atual, mín/máxima do dia, cobertura de nuvens e chuva acumulada. Fundo muda de cor conforme o clima |
| **7 cards de métricas** | Umidade, ponto de orvalho, vento, chuva, pressão, índice UV e visibilidade |
| **Arco nascer/pôr do sol** | SVG animado com posição real do sol baseada na hora atual |
| **Fase da lua** | Calculada via período sinódico (29,53 dias); emoji dinâmico + barra de iluminação |
| **Qualidade do ar (IQA)** | Índice com categoria (Bom → Perigoso) e barra de gradiente colorido |
| **Previsão 24 horas** | Cards roláveis com ícone, temperatura e precipitação por hora |
| **Barras de temperatura semanal** | Faixa mín–máx por dia em gradiente azul→vermelho |
| **Condições do mar** | Altura das ondas, temperatura e estado (Calmo / Agitado / Muito agitado) |
| **Vento** | Velocidade, direção com seta rotacionada e rajadas estimadas |
| **Neve e gelo** | Acúmulo do dia, temperatura mínima e alerta de risco de gelo |

### Interatividade
| Recurso | Descrição |
|---|---|
| **Seletor de cidade** | 5 cidades brasileiras: São Paulo, Rio de Janeiro, Curitiba, Manaus e Florianópolis |
| **Seletor de data** | Navegação entre os últimos 3 dias e próximos 7 dias |
| **Modo comparação** | Exibe todas as cidades lado a lado em cards compactos |
| **Download CSV** | Exporta os dados do dia e cidade selecionados |
| **Modo claro/escuro** | Toggle no cabeçalho altera o tema via CSS custom properties |
| **Auto-refresh** | Dados atualizam automaticamente a cada 5 minutos |

### Animações e alertas
| Recurso | Descrição |
|---|---|
| **Animação de chuva/neve/tempestade** | Canvas HTML5 com partículas geradas em JavaScript, ativado automaticamente pela condição do clima |
| **Alertas climáticos** | Banner vermelho para condições severas (tempestade, UV extremo, geada, vendaval) |
| **Toast de notificação** | Popup deslizante exibido ao detectar condição severa |

---

## Stack tecnológica

| Camada | Tecnologia |
|---|---|
| Linguagem | R 4.x |
| Framework web | [Shiny](https://shiny.posit.co/) + [bslib](https://rstudio.github.io/bslib/) (Bootstrap 5) |
| Manipulação de dados | [dplyr](https://dplyr.tidyverse.org/), [lubridate](https://lubridate.tidyverse.org/) |
| Visualização | HTML, CSS, SVG inline — **sem ggplot2 / plotly** |
| Animações | JavaScript vanilla (Canvas API + MutationObserver) |
| Ícones | [Font Awesome 6](https://fontawesome.com/) |

---

## Estrutura do projeto

```
ClimaTempo/
├── data.R        # Geração de dados fictícios multi-cidade (11 dias, horário)
├── ui.R          # Layout da interface (bslib page_fluid)
├── server.R      # Lógica reativa: cálculos, renderUI, download, alertas
└── www/
    ├── style.css  # Tema dark/light, animações CSS, responsividade mobile
    └── weather.js # Canvas de partículas, toast, toggle de tema
```

### `data.R`
Gera um `data.frame` chamado `weather` com dados horários para 5 cidades, cobrindo 3 dias passados e 7 dias futuros a partir da execução. Colunas geradas:

`DateTime`, `Date`, `Hora`, `Cidade`, `Temp`, `Sensacao`, `Umidade`, `VentoVel`, `VentoDir`, `Precip`, `Neve`, `Nuvem`, `Condicao`, `UV`, `Visib`, `Pressao`, `Onda`, `TempMar`, `PontoOrvalho`, `IQA`

### `server.R`
Contém todos os `renderUI` reativos, helpers de cálculo (fase da lua, arco solar, geração de alertas) e o `downloadHandler` para exportação CSV.

---

## Instalação e execução

### Pré-requisitos
- [R 4.x](https://cran.r-project.org/)
- [RStudio](https://posit.co/download/rstudio-desktop/) *(recomendado)*

### 1. Clone o repositório

```bash
git clone https://github.com/LeviLucena/ClimaTempo.git
cd ClimaTempo
```

### 2. Instale os pacotes

```r
install.packages(c("shiny", "bslib", "dplyr", "lubridate"))
```

### 3. Execute o app

```r
shiny::runApp(".")
```

Ou, no RStudio, abra qualquer arquivo `.R` do projeto e clique em **Run App**.

---

## Dados

Os dados são **totalmente fictícios** e gerados proceduralmente via distribuições estatísticas (normal, Poisson) com semente fixa (`set.seed(42)`), garantindo reprodutibilidade. Os parâmetros por cidade (temperatura base, probabilidade de chuva) são ajustados para refletir o clima real de cada região de forma aproximada.

---

## Contribuição

Contribuições são bem-vindas. Abra uma *issue* para reportar problemas ou uma *pull request* para propor melhorias.

---

## Licença

Distribuído sob a [Licença MIT](LICENSE.md).

---

## Autor

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Levi%20Lucena-blue?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/levilucena/)
