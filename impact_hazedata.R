library(rvest)

path <- "http://api.nea.gov.sg/api/WebAPI/?dataset=pm2.5_update&keyref=***REMOVED***"

out <- rvest::html(path)
out

region <- out %>% html_nodes("id") %>% html_text
region

latitude <- out %>% html_nodes("latitude") %>% html_text
latitude

longitude <- out %>% html_nodes("longitude") %>% html_text
longitude

timestamp  <- out %>% html_nodes("record") %>% html_attr("timestamp")
timestamp

reading  <- out %>% html_nodes("reading") %>% html_attr("value")
reading 

df <- data.frame(region,latitude,longitude,reading, timestamp)
df
