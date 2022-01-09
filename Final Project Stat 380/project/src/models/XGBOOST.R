rm(list = ls())
library(data.table)
library(Rtsne)
library(ggplot2)
library(utils)
library(dplyr)
library(xgboost)
library(reshape2)



gig <- fread("./project/volume/data/interim/master2.csv",stringsAsFactors = F)#formerly master
id<-fread("./project/volume/data/interim/id.csv",stringsAsFactors = F)
colnames(id) <- c("id")
cleantrain<-fread("./project/volume/data/interim/train_data_clean.csv",stringsAsFactors = F)
cleantest<-fread("./project/volume/data/interim/test_data_clean.csv",stringsAsFactors = F)

#Extract and train xgboost on tsne
gig<- cbind(id,gig)
gig<-gig%>%select(id, tsne_1, tsne_2)

train<-head(gig,200)
test<-tail(gig,20554)
###############GUCCCI
###XGBOOST
test$id <- NULL
train$id <- NULL
###

###################

#label
y.train<-cleantrain$number
y.train<-as.numeric(as.integer(y.train))
#xgb matrix


set.seed(9001)
#convert to matrix
train <- as.matrix(train,label=y.train,missing=NA)
test <- as.matrix(test, missing=NA)


#xgb matrix
train <- xgb.DMatrix(train,label=y.train,missing=NA)
test <- xgb.DMatrix(test, missing=NA)


# Initialize my table
hyper_perm_tune <- NULL
#----------------------------------#
#     Use cross validation         #
#----------------------------------#

param <- list(  objective           = "multi:softprob", #required
                eval_metric         = "mlogloss",   #required
                gamma               = 0.02,   
                booster             = "gbtree",
                eval_metric         = "merror",
                eta                 = 0.085, #0.3,0.1,0.05  Tune this
                max_depth           =  7,    #5 best Tune that for best results
                subsample           = 0.76,
                tree_method = 'hist'
                #label=y.train
)


XGBfit <- xgb.cv(params = param,
                 nfold = 15, 
                 nrounds = 1000, #formerly 10000
                 missing = NA,
                 data = train,
                 print_every_n = 1,
                 early_stopping_rounds = 200,
                 num_class = 10,
                 row = TRUE
                 )   



best_tree_n <- unclass(XGBfit)$best_iteration
new_row <- data.table(t(param))
new_row$best_tree_n <- best_tree_n

test_error <- unclass(XGBfit)$evaluation_log[best_tree_n,]$test_rmse_mean
new_row$test_error <- test_error
hyper_perm_tune <- rbind(new_row, hyper_perm_tune)

fwrite(hyper_perm_tune, file="./project/volume/data/processed/Hyper_Perm_Tune.csv", row.names = FALSE, quote=FALSE)


#----------------------------------#
# fit the model to all of the data #
#----------------------------------#

watchlist <- list( train = train)



XGBfit <- xgb.train( params = param,
                     nrounds = best_tree_n,
                     missing = NA,
                     data = train,
                     watchlist = watchlist,
                     print_every_n = 1,
                     num_class=10,
                    
                     )

pred.test <- predict(XGBfit, newdata = test)


res <- cbind.data.frame(split(pred.test, rep(1:10, times=length(pred.test)/10)), stringsAsFactors=F)

names(res)<- c("subredditcars","subredditCooking","subredditMachineLearning",
                  "subredditmagicTCG","subredditpolitics","subredditReal_Estate",
                  "subredditscience","subredditStockMarket","subreddittravel","subredditvideogames")
submission<-cbind(id=cleantest$id,res)



fwrite(submission, file="./project/volume/data/processed/xgboost(Test).csv", row.names = FALSE, quote=FALSE)




