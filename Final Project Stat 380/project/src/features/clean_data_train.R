rm(list = ls())
library(data.table)

#- Read in data
data <- fread("./project/volume/data/raw/train_data.csv")
#- Remove all the empty strings
data <- data[!data[,text == ""]]

text<-data$text
id<-data$id
data <- data[, -c(1,2)]
data$ID <- seq.int(nrow(data))
long=melt(data,id="ID")
long=long[which(long$value==1),]
long$ID <- as.numeric(as.character(long$ID))
long<-long[order(long$ID),]
long <- long[, -c(1,3)]
names(long)="subreddit"
#### assign numbers
long$number <- as.numeric( factor(long$subreddit) ) -1

long<-cbind(id,long,text)


###save
fwrite(long,"./project/volume/data/interim/train_data_clean.csv")
