#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("PM Haze"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      selectInput("type", "Select Type:", c("PSI", "PM25"))
    ),
    
    # Show a map plot of the values
    mainPanel(
      plotOutput("plot_map")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  sg_map <- qmap(location="Singapore", zoom=11, source="stamen", maptype="watercolor")
  
  latest_reading = data.frame(
    lon = c(103.82000, 103.82000, 103.94000, 103.70000, 103.82000),
    lat = c(1.41803, 1.35735, 1.35735, 1.35735, 1.29587),
    id = c("NO", "CE", "EA", "WE", "SO"),
    val = c(45, 25, 28, 5, 136)
  )

  psi_cat_range = list(low = c(0, 51, 101, 201, 301, 401),
                       high = c(50, 100, 200, 300, 400, 500))
  pm25_cat_range = list(low = c(0, 13, 56, 151, 251, 351),
                        high = c(12, 55, 150, 250, 350, 500))
  class_map = c("Good", "Moderate", "Unhealthy", "Very unhealthy", "Hazardous")
  
  pm25_to_psi = function(val) {
    ix = sapply(val, function(v) which(v>=pm25_cat_range$low & v<pm25_cat_range$high))
    (psi_cat_range$high[ix] - psi_cat_range$low[ix]) / 
      (pm25_cat_range$high[ix] - pm25_cat_range$low[ix]) * 
      (val - pm25_cat_range$low[ix]) +
      psi_cat_range$low[ix]
  }
  
  pm25_to_class = function(val) {
    ix = sapply(val, function(v) which(v>=pm25_cat_range$low & v<pm25_cat_range$high))
    col_map[ix]
  }
  psi_to_class = function(val) {
    ix = sapply(val, function(v) which(v>=pm25_cat_range$low & v<pm25_cat_range$high))
    col_map[ix]
  }
  
  output$plot_map = renderPlot({
    plotDF = latest_reading
    plotDF$Value = switch(input$type,
                          "PSI" = round(pm25_to_psi(plotDF$val)),
                          "PM25" = plotDF$val)
    plotDF$Classification = switch(input$type,
                                   "PSI" = psi_to_color(plotDF$val),
                                   "PM25" = pm25_to_color(plotDF$val))
    sg_map + 
      geom_label(aes(label=Value, col=Classification), data=plotDF, size=10) +
      scale_color_manual(values=c("Good"="green","Moderate"="blue","Unhealthy"="yellow","Very unhealthy"="orange","Hazardous"="red")) +
      theme(legend.position = "")
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

