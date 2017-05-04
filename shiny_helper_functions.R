# Helper functions for Shiny app
library(ggmap)
library(rvest)
library(data.table)
library(fasttime)

# Parameter settings
category_df = data.frame(pm25.low = c(0, 13, 56, 151, 251, 351),
                         pm25.high = c(12, 55, 150, 250, 350, 500) + 1, # Should be closed range
                         psi.low = c(0, 51, 101, 201, 301, 401),
                         psi.high = c(50, 100, 200, 300, 400, 500) + 1, # Should be closed range
                         category = c("Good", "Moderate", "Unhealthy", "Very unhealthy", "Hazardous", "Hazardous"))
haze_color_map = c("Good"="green","Moderate"="blue","Unhealthy"="yellow","Very unhealthy"="orange","Hazardous"="red")
map_list = list()
hist_file_name = "hist_readings.csv"
if (! file.exists(hist_file_name)) {
  cat("Creating new historical readings data base.")
  writeLines("region,latitude,longitude,reading,timestamp", hist_file_name)
}
hist_df = fread(hist_file_name, header = TRUE,
                colClasses = c("factor", "numeric", "numeric", "numeric", "character"))
hist_df[, timestamp := as.POSIXct(timestamp, format = "%Y-%m-%d %H:%M:%S")]

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
get_SG_map = function(map_type) {
  if ( !(map_type %in% names(map_list)) ) {
    sp = strsplit(map_type, ":")[[1]]
    source = sp[1]; type = sp[2]
    map_list[[map_type]] <<- get_map(location="Singapore", zoom=11, 
                                     source=source, maptype=type)
  }
  map_list[[map_type]]
}

# xml parsing
get_latest_reading = function() {
  hist_df[timestamp == max(timestamp), .SD, by = region]
}

update_hist_reading = function() {
  path <- "http://api.nea.gov.sg/api/WebAPI/?dataset=pm2.5_update&keyref=***REMOVED***"
  # read the data using rvest package
  out <- read_html(path)
  region <- out %>% html_nodes("id") %>% html_text
  latitude <- as.numeric(out %>% html_nodes("latitude") %>% html_text)
  longitude <- as.numeric(out %>% html_nodes("longitude") %>% html_text)
  timestamp  <- as.POSIXct(out %>% html_nodes("record") %>% html_attr("timestamp"),
                           format = "%Y%m%d%H%M%S")
  reading  <- as.numeric( out %>% html_nodes("reading") %>% html_attr("value") )
  df <- data.table(region, latitude, longitude, reading, timestamp)
  # Find if does not exist in hist_df and add
  found = tail(duplicated(rbind(hist_df, df)), nrow(df))
  hist_df <<- rbind(hist_df, df[!found, ])
  write.table(x=df[!found, ], file=hist_file_name, append = TRUE, sep =",", row.names = FALSE, col.names = FALSE)
  max(hist_df$timestamp)
}