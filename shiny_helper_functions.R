# Helper functions for Shiny app
library(ggmap)
library(rvest)
library(data.table)

# Parameter settings ------------------------------------------------------

# The main file to store/read the values from
hist_file_name = "hist_readings.csv"
# Data frame with the range of values for different categories
category_df = data.frame(pm25.low = c(0, 13, 56, 151, 251, 351),
                         pm25.high = c(12, 55, 150, 250, 350, 500) + 1, # Should be closed range
                         psi.low = c(0, 51, 101, 201, 301, 401),
                         psi.high = c(50, 100, 200, 300, 400, 500) + 1, # Should be closed range
                         category = c("Good", "Moderate", "Unhealthy", "Very unhealthy", "Hazardous", "Hazardous"))
# Map from the categories to the color to be used to print the label
haze_color_map = c("Good"="green","Moderate"="blue","Unhealthy"="yellow","Very unhealthy"="orange","Hazardous"="red")
# Variable to hold the maps downloaded using get_map. Dynamic storage prevents delay while refreshing
map_list = list()


# Historical update -------------------------------------------------------

# Creates the hist_file_name if not found
if (! file.exists(hist_file_name)) {
  cat("Creating new historical readings data base.")
  writeLines("region,latitude,longitude,reading,timestamp", hist_file_name)
}
# Reads the previously stored values
hist_df = fread(hist_file_name, header = TRUE,
                colClasses = c("factor", "numeric", "numeric", "numeric", "character"))
hist_df[, timestamp := as.POSIXct(timestamp, format = "%Y%m%d%H%M%S")]


# Conversion functions (PSI<>PM) ------------------------------------------

pm25_to_psi = function(pm_values) {
  ix = index_in_range(pm_values, "PM25")
  (category_df$psi.high[ix] - category_df$psi.low[ix]) / 
    (category_df$pm25.high[ix] - category_df$pm25.low[ix]) * 
    (pm_values - category_df$pm25.low[ix]) +
    category_df$psi.low[ix]
}

# Map functions -----------------------------------------------------------

# Download map if not previously done. Return the stored map
get_SG_map = function(map_type) {
  if ( !(map_type %in% names(map_list)) ) {
    sp = strsplit(map_type, ":")[[1]]
    source = sp[1]; type = sp[2]
    map_list[[map_type]] <<- get_map(location="Singapore", zoom=11, 
                                     source=source, maptype=type)
  }
  map_list[[map_type]]
}

# NEA scrapping functiions ------------------------------------------------

# Updates hist_df and hist_file_name if new readings are obtained. Returns the latest timestamp in hist_df
update_hist_reading = function() {
  path <- "http://api.nea.gov.sg/api/WebAPI/?dataset=pm2.5_update&keyref=***REMOVED***"
  out <- read_html(path) # read the data using rvest package
  # # Un comment followin lines for later debugging
  # f = file("log.txt", "a")
  # writeLines(c(as.character(Sys.time()), as.character(out)), f)
  # close(f)
  region <- out %>% html_nodes("id") %>% html_text
  latitude <- as.numeric(out %>% html_nodes("latitude") %>% html_text)
  longitude <- as.numeric(out %>% html_nodes("longitude") %>% html_text)
  timestamp  <- as.POSIXct(out %>% html_nodes("record") %>% html_attr("timestamp"),
                           format = "%Y%m%d%H%M%S")
  reading  <- as.numeric( out %>% html_nodes("reading") %>% html_attr("value") )
  df <- data.table(region, latitude, longitude, reading, timestamp)
  
  # Find if readings do not exist in hist_df and add
  found = tail(duplicated(rbind(hist_df, df)), nrow(df))
  hist_df <<- rbind(hist_df, df[!found, ])
  df[, timestamp := as.character(timestamp, format = "%Y%m%d%H%M%S")]
  write.table(x=df[!found, ], file=hist_file_name, append = TRUE, sep =",", row.names = FALSE, col.names = FALSE)
  max(hist_df$timestamp)
}

# Historical Extraction Functions -----------------------------------------

get_latest_reading = function() {
  hist_df[timestamp == max(timestamp), .SD, by = region]
}

# Helper functions --------------------------------------------------------

# Extract the category for each value
get_category = function(values, type) {
  ix = index_in_range(values, type)
  category_df$category[ix]
}

# Convinence function to find index in category_df
index_in_range = function(value, type) {
  r = switch(type, 
             "PSI" = category_df[, c("psi.low", "psi.high")],
             "PM25" = category_df[, c("pm25.low", "pm25.high")])
  sapply(value, function(v) which(v>=r[, 1] & v<r[, 2]))
}