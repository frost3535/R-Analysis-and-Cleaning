rm(list = ls())
library(data.table)
library(Rtsne)
library(ggplot2)
library(ClusterR)
library(xgboost)


set.seed(9001)
#- For singling out
# emd_data[PSU_ID == ""]

###Prep Solution and read data
data <- fread("./project/volume/data/interim/gigaset.csv")

#- store and remove the id/text types
id <- data$id
data$id <- NULL

write.table(id, file="./project/volume/data/interim/id.csv", row.names = FALSE, quote = FALSE)
text<- data$text
data$text <- NULL
#PCA
pca <- prcomp(data, scale=TRUE)#limit components to test faster
# extract the components 
pca_dt <- data.table(unclass(pca)$x)


#TSNE
tsne <- Rtsne(pca_dt, 
              pca=F, #(Saving time using PCA before)
              perplexity = 30,#best run 475.
              max_iter = 1000,#2000
              check_duplicates = F)
tsne_d1<-data.table(tsne$Y)

#TSNE 2nd
tsnea <- Rtsne(tsne_d1, 
              pca=F, #(Saving time using PCA before)
              perplexity = ,# best run 500
              max_iter = 40,#2000
              check_duplicates = F)
tsne_d2<-data.table(tsnea$Y)
# #  #TSNE 3rd
 tsneb <- Rtsne(tsne_d2, 
                pca=F, #(Saving time using PCA before)
               perplexity = 45,
               max_iter = 2000,
             check_duplicates = F)
 tsne_d3<-data.table(tsneb$Y)
# #  #  
 #  #  #TSNE 4th
 tsnec <- Rtsne(tsne_d3, 
                  pca=F, #(Saving time using PCA before)
                perplexity = 50,#
                max_iter = 2000,
               check_duplicates = F)
 tsne_d4<-data.table(tsnec$Y)
# #   
# # #TSNE 5th round
# #tsne_dd <- Rtsne(tsne_d4, 
# #                 pca=F, #(Saving time using PCA before)
# #                  perplexity = 500,
# #                  max_iter = 2000,
# #                  check_duplicates = F)
# # tsne_d5<-data.table(tsne_dd$Y)

#################
colnames(tsne_d4) <- c("tsne_1","tsne_2")

ggplot(tsne_d4,aes(x=tsne_1,y=tsne_2))+geom_point()
#write tsne results
fwrite(tsne_d4, file="./project/volume/data/interim/tsne.csv", row.names = FALSE, quote=FALSE)
master<-cbind(data,tsne_d4)
#write masterfile
fwrite(master, file="./project/volume/data/interim/master.csv", row.names = FALSE, quote=FALSE)



plot(tsnea$Y,col=clusterInfo$cluster_labels)
master2<-cbind(data,master)
fwrite(master2, file="./project/volume/data/interim/master2.csv", row.names = FALSE, quote=FALSE)



