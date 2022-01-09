#cbind the train embedding to the raw train and the test embedding to the raw test, 
#then rbind the train and test together.
rm(list = ls())
library(httr)
library(data.table)

EmdTrain <- fread("./project/volume/data/interim/Emd_DT_Train.csv")
EmdTest <- fread('./project/volume/data/interim/Emd_DT_Test.csv')
#remove ids 
trainraw <- fread('./project/volume/data/raw/train_data.csv')

trainraw = subset(trainraw, select = c(text, id) )
testraw <- fread('./project/volume/data/raw/test_data.csv')
testraw = subset(testraw, select = c(text, id) )

Train<- cbind(trainraw,EmdTrain)
Test<-cbind(testraw,EmdTest)

Gigaset<-rbind(Train,Test)

fwrite(Gigaset,"./project/volume/data/interim/gigaset.csv")