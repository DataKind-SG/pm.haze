library(rvest)

# NEA URL with key
path <- "http://api.nea.gov.sg/api/WebAPI/?dataset=pm2.5_update&keyref=***REMOVED***"

# read the data using rvest package
# out <- rvest::html(path) #rvest::html is depreceated
out <- read_html(path)
out

region <- out %>% html_nodes("id") %>% html_text
region

latitude <- out %>% html_nodes("latitude") %>% html_text
latitude

longitude <- out %>% html_nodes("longitude") %>% html_text
longitude

# Read the XML attribute "timestamp" from Node "Record"
timestamp  <- out %>% html_nodes("record") %>% html_attr("timestamp")
timestamp

# Read the XML attribute "value" from Node "reading"
reading  <- out %>% html_nodes("reading") %>% html_attr("value")
reading 

# store the required info into a dataframe
df <- data.frame(region,latitude,longitude,reading, timestamp)
df

# Todo
# timestamp can be formatted is needed

# output format
#region latitude longitude reading      timestamp
#1    rNO  1.41803 103.82000      33 20170503210000
#2    rCE  1.35735 103.82000      23 20170503210000
#3    rEA  1.35735 103.94000      15 20170503210000
#4    rWE  1.35735 103.70000      26 20170503210000
#5    rSO  1.29587 103.82000      31 20170503210000
