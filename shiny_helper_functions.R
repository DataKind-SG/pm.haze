# Helper functions for Shiny app
library(ggmap)
library(rvest)

# Parameter settings
category_df = data.frame(pm25.low = c(0, 13, 56, 151, 251, 351),
                         pm25.high = c(12, 55, 150, 250, 350, 500) + 1, # Should be closed range
                         psi.low = c(0, 51, 101, 201, 301, 401),
                         psi.high = c(50, 100, 200, 300, 400, 500) + 1, # Should be closed range
                         category = c("Good", "Moderate", "Unhealthy", "Very unhealthy", "Hazardous", "Hazardous"))
haze_color_map = c("Good"="green","Moderate"="blue","Unhealthy"="yellow","Very unhealthy"="orange","Hazardous"="red")
map_list = list(google = list(),
                stamen = list())

# Conversion functions

pm25_to_psi = function(pm_values) {
  ix = index_in_range(pm_values, "PM25")
  (category_df$psi.high[ix] - category_df$psi.low[ix]) / 
    (category_df$pm25.high[ix] - category_df$pm25.low[ix]) * 
    (pm_values - category_df$pm25.low[ix]) +
    category_df$psi.low[ix]
}

# Properties functions

get_category = function(values, type) {
  ix = index_in_range(values, type)
  category_df$category[ix]
}

# Helper functions

index_in_range = function(value, type) {
  r = switch(type, 
             "PSI" = category_df[, c("psi.low", "psi.high")],
             "PM25" = category_df[, c("pm25.low", "pm25.high")])
  sapply(value, function(v) which(v>=r[, 1] & v<r[, 2]))
}

# Map functions
get_SG_map = function(source, type) {
  if ( !(type %in% names(map_list[[source]])) )
    map_list[[source]][[type]] <<- get_map(location="Singapore", zoom=11, 
                                           source=source, maptype=type)
  map_list[[source]][[type]]
}

# xml parsing
get_latest_reading = function() {
  path <- "http://api.nea.gov.sg/api/WebAPI/?dataset=pm2.5_update&keyref=***REMOVED***"
  # read the data using rvest package
  out <- read_html(path)
  region <- out %>% html_nodes("id") %>% html_text
  latitude <- as.numeric(out %>% html_nodes("latitude") %>% html_text)
  longitude <- as.numeric(out %>% html_nodes("longitude") %>% html_text)
  # Read the XML attribute "timestamp" from Node "Record"
  timestamp  <- as.POSIXlt(out %>% html_nodes("record") %>% html_attr("timestamp"),
                           format = "%Y%m%d%H%M%S")
  # Read the XML attribute "value" from Node "reading"
  reading  <- as.numeric( out %>% html_nodes("reading") %>% html_attr("value") )
  # store the required info into a dataframe
  df <- data.frame(region,latitude,longitude,reading, timestamp)
  df
}