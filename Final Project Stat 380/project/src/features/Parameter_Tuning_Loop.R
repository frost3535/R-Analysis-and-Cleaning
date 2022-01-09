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


####################TUNE

set.seed(100)
for (iter in 1:100) {
  param <- list(objective = "multi:softprob",
                eval_metric = "mlogloss",
                max_depth = sample(6:10, 1),
                eta = runif(1, .01, .3), 
                subsample = runif(1, .6, .9),
                min_child_weight = sample(1:50, 1),
                max_delta_step = sample(1:10, 1),
                num_class=10
  )
  cv.nround <-  1000
  cv.nfold <-  5 
  seed.number  <-  sample.int(10000, 1)
  set.seed(seed.number)
  mdcv <- xgb.cv(data = train, params = param,  
                 nfold = cv.nfold, nrounds = cv.nround,
                 verbose = F, early_stopping_rounds = 10, maximize = FALSE)
  min_logloss_index  <-  mdcv$best_iteration
  min_logloss <-  mdcv$evaluation_log[min_logloss_index]$test_logloss_mean
  
  if (min_logloss < best_logloss) {
    best_logloss <- min_logloss
    best_logloss_index <- min_logloss_index
    best_seednumber <- seed.number
    best_param <- param
  }
}

# The best index (min_rmse_index) is the best "nround" in the model
nround = best_logloss_index
set.seed(best_seednumber)
xg_mod <- xgboost(data = test, params = best_param, nround = nround, verbose = F)

###################