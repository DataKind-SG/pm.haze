#### SIMULATE PM2.5 DATASET
d <- data.frame(Timestamp="20170503200000", Region=c("NO","CE","EA","WE","SO"),
                Value=c(45,25,28,35,36))
d$Year <- substr(d$Timestamp,1,4)
d$Month <- substr(d$Timestamp,5,6)
d$Day <- substr(d$Timestamp,7,8)
d$Time <- substr(d$Timestamp,9,12)
d$Longtitude <- c(103.82000, 103.82000, 103.94000, 103.70000, 103.82000)
d$Latitude <- c(1.41803, 1.35735, 1.35735, 1.35735, 1.29587)
d$Classification <- NA

# function to classify PSI reading into NEA categories
get_classification <- function(psi){
  cl <- rep(NA,length(psi))
  for (i in seq(1,length(psi))){
    if (psi[i]<=50){
      cl[i] <- "Good"
    }
    else if (psi[i] <= 100){
      cl[i] <- "Moderate"
    }
    else if (psi[i] <= 200){
      cl[i] <- "Unhealthy"
    }
    else if (psi[i] <= 300){
      cl[i] <- "Very unhealthy"
    }
    else { cl[i] <- "Hazardous"}
  }
  return(cl)
}
# d$Classification <- get_classification(d$Value) #to classify
d$Classification <- get_classification(c(9,99,199,299,500)) #fake categories to test

library(ggmap)
sg_map <- get_map(location="Singapore", zoom=11) #google map
plot(sg_map)

sg_map <- get_map(location="Singapore", zoom=11, source="stamen", maptype="toner") #black white map
plot(sg_map)

sg_map <- qmap(location="Singapore", zoom=11, source="stamen", maptype="watercolor") #pretty map
sg_map + 
  annotate("rect", xmin=d$Longtitude-0.025, xmax=d$Longtitude+0.025, 
           ymin=d$Latitude-0.025, ymax=d$Latitude+0.025,fill="grey80") +
  geom_text(aes(Longtitude, Latitude, label=Value, col=Classification), data=d, size=10) +
  scale_color_manual(values=c("green","blue","yellow","orange","red"))
  
  
