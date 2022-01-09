rm(list = ls())
library(data.table)

#- Read in data
data <- fread("./project/volume/data/raw/test_data.csv")
#- Remove all the empty strings
data <- data[!data[,Sentence == ""]]

###save
fwrite(data,"./project/volume/data/interim/test_data_clean.csv")
