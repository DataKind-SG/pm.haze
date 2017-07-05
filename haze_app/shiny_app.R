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
      radioButtons("type", "Select variable:", c("PSI", "PM25")),
      uiOutput("ui_t_range"), # Slider with time range that is updated when new readings
      selectInput("map_type", "Select map type:", 
                  c(paste0("google:", c("terrain", "satellite", "roadmap", "hybrid")),
                    paste0("stamen:", c("watercolor", "toner")))
                  ),
      checkboxGroupInput("region", "Select regions to plot",
                         choices = c("rNO", "rCE", "rEA", "rWE", "rSO"),
                         selected = c("rNO", "rCE", "rEA", "rWE", "rSO"))
      
    ),
    
    # Show a map plot of the values
    mainPanel(
      plotOutput("plot_map"),
      plotOutput("plot_ts"),
      textOutput("txt_update_info") # Shows the timestamp of latest reading available
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  # Helper function to calculate the time to next hour:00:00 + 5mins
  ms_to_next_update = function() (60 + 5 - minute(Sys.time()))*60*1000
  
  # Updates the local data base and sets text output to latest time stamp
  output$txt_update_info = reactive({
    invalidateLater(ms_to_next_update(), session)
    paste("Last updated reading from:", as.character(update_hist_reading()))
  })
  
  # Updates the time slider
  output$ui_t_range = renderUI({
    invalidateLater(ms_to_next_update(), session)
    mi = min(hist_df$timestamp)
    ma = max(hist_df$timestamp)
    sliderInput("t_range", "Time range to plot:", 
                mi, ma, value = c(mi, ma))
  })
  
  # Gets latest reading and updates the map with given type and variable
  output$plot_map = renderPlot({
    sg_map = get_SG_map(input$map_type)
    plotDF = get_latest_reading()
    plotDF$Value = switch(input$type,
                          "PSI" = round(pm25_to_psi(plotDF$reading)),
                          "PM25" = plotDF$reading)
    plotDF$Classification = get_category(plotDF$Value, input$type)
    ggmap(sg_map) + 
      geom_label(data=plotDF, aes(longitude, latitude, 
                                  label=Value, col=Classification), size=10) +
      scale_color_manual(values = haze_color_map) +
      theme(legend.position = "")+
      ggtitle(paste(input$type, "values recorded at", max(plotDF$timestamp)))
  })
  
  # Generates the time-series plot considering in the selected range and regions
  output$plot_ts = renderPlot({
    validate(
      need(length(input$region)>0, "Please select at least one region")
    )
    plotDF = hist_df[(timestamp %between% input$t_range) & (region %in% c(input$region))]
    validate(
      need(nrow(plotDF)>0, "Data not recorded for selected time range")
    )
    plotDF$Value = switch(input$type,
                          "PSI" = round(pm25_to_psi(plotDF$reading)),
                          "PM25" = plotDF$reading)
    ggplot(plotDF, aes(x = timestamp, y = Value, col = region))+
      geom_point(aes(shape = region))+
      geom_line()+
      ylab(input$type)+
      theme_light()+
      ggtitle(paste("Historical trend of", input$type, "for selected region and time range"))
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

