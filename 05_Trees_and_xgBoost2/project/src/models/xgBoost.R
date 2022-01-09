library(data.table)
library(caret)
library(Metrics)
library(xgboost)

#https://rpubs.com/jeandsantos88/search_methods_for_hyperparameter_tuning_in_r
test <- fread("./project/volume/data/interim/Stat_380_test.csv",stringsAsFactors = F)
train <- fread("./project/volume/data/interim/Stat_380_train.csv",stringsAsFactors = F)

###
test_labels <- test$Id
test$Id <- NULL
train$Id <- NULL
test$SalePrice <- NA
###


###################
set.seed(9001)
y.train <- train$SalePrice
y.test <- test$SalePrice


dummies <- dummyVars(SalePrice~ ., data = train)
x.train <- predict(dummies, newdata = train)
x.test <- predict(dummies, newdata = test)

#remove label
dtrain <- xgb.DMatrix(x.train,label=y.train,missing=NA)
dtest <- xgb.DMatrix(x.test, missing=NA)


# Initialize my table
hyper_perm_tune <- NULL
#----------------------------------#
#     Use cross validation         #
#----------------------------------#

param <- list(  objective           = "reg:squarederror",
                gamma               = 0.02,   
                booster             = "gbtree",
                eval_metric         = "rmse",
                eta                 = 0.25,   
                max_depth           = 2,     
                subsample           = 1.0,
                colsample_bytree    = 1.0,    
                tree_method = 'hist'  
)


XGBfit <- xgb.cv(params = param,
                 nfold = 15, 
                 nrounds = 15000, #formerly 10000
                 missing = NA,
                 data = dtrain,
                 print_every_n = 1,
                 early_stopping_rounds = 10)   



best_tree_n <- unclass(XGBfit)$best_iteration
new_row <- data.table(t(param))
new_row$best_tree_n <- best_tree_n

test_error <- unclass(XGBfit)$evaluation_log[best_tree_n,]$test_rmse_mean
new_row$test_error <- test_error
hyper_perm_tune <- rbind(new_row, hyper_perm_tune)

#----------------------------------#
# fit the model to all of the data #
#----------------------------------#

watchlist <- list( train = dtrain)



XGBfit <- xgb.train( params = param,
                     nrounds = best_tree_n,
                     missing = NA,
                     data = dtrain,
                     watchlist = watchlist,
                     print_every_n = 1)



pred.test <- predict(XGBfit, newdata = dtest)



submission <- data.frame(Id=test_labels, SalePrice= pred.test)
fwrite(submission, file="./project/volume/data/processed/xgboost.csv", row.names = FALSE, quote=FALSE)

