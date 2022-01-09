rm(list = ls())
library(httr)
library(data.table)


set.seed(1)

getEmbeddings <- function(text){
  input <- list(
    instances = list( text)
  )
  res <- POST("https://dsalpha.vmhost.psu.edu/api/use/v1/models/use:predict", body = input,encode = "json", verbose())
  emb<-unlist(content(res)$predictions)
  emb
}

data <- fread('./project/volume/data/interim/test_data_clean.csv')
emb_dt <- NULL
as.data.frame.table(emb_dt)

#loop goes here
for (i in 1:length(data$text)){
  emb_dt<-rbind(emb_dt,getEmbeddings(data$text[i]))
  
}
emb_dt<-data.table(emb_dt)

#tsne<-Rtsne(emb_dt,perplexity=10)
#tsne_dt<-data.table(tsne$Y)

#tsne_dt$text<-data$text
#tsne_dt$id<-data$id 

fwrite(emb_dt,"./project/volume/data/interim/Emd_DT_Test.csv")