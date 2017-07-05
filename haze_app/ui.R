#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
fluidPage(
  
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