#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
source("shiny_helper_functions.R")

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("PM Haze"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      selectInput("type", "Select Variable:", c("PSI", "PM25")),
      uiOutput("ui_maptype"),
      selectInput("map_source", "Select Source of Map:", c("google", "stamen"))
    ),
    
    # Show a map plot of the values
    mainPanel(
      plotOutput("plot_map")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  latest_reading = get_latest_reading()
  
  output$plot_map = renderPlot({
    sg_map = get_SG_map(input$map_source, input$maptype)
    plotDF = latest_reading
    plotDF$Value = switch(input$type,
                          "PSI" = round(pm25_to_psi(plotDF$reading)),
                          "PM25" = plotDF$reading)
    plotDF$Classification = get_category(plotDF$Value, input$type)
    ggmap(sg_map) + 
      geom_label(data=plotDF, aes(longitude, latitude, 
                                  label=Value, col=Classification), size=10) +
      scale_color_manual(values = haze_color_map) +
      theme(legend.position = "")
  })
  
  output$ui_maptype = renderUI({
    switch(input$map_source,
           "google" = selectInput("maptype", "Select Type of Map:",
                                  c("terrain", "satellite", "roadmap", "hybrid")),
           "stamen" = selectInput("maptype", "Select Type of Map:",
                                  c("watercolor", "toner"))
    )
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

