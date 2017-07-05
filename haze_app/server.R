#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

function(input, output, session) {
  source("shiny_helper_functions.R")  
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