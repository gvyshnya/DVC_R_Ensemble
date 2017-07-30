# Competition: https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/
# This is a file to perform 
# - xgboost model training (linear booster used)
# - predition on the imputed testing set, using the fitted xgboost model 
# - preparation of a Kaggle submission file 
# It is intended to run from a command line in a batch mode, using the Rscript command below: 
# Rscript --vanilla code/xgboost.R data/train_imputed.csv data/test_imputed.csv 10 2 0.0001 1 data/xgboost_submission.csv
# 7 arguments are required 
# - input file name for imputed training data csv,
# - input file name for imputed testing data csv
# - nrounds - number of rounds in the xgboost search (integer)
# - depth - depth of boosting search (integer)
# - alpha  - one of the linear booster-specific parameters (float)
# - lambda - one of the linear boster-specific parameters (float)
# - output file name for the result submission csv file (in a ready-for-Kaggle-upload format)
#
# Note: please refer to http://xgboost.readthedocs.io/en/latest/R-package/xgboostPresentation.html or other
#       links in the comments below for more details on xgboost parameters

library(caret)
library(plyr)
library(dplyr)
library(caTools)
library(xgboost)

strt<-Sys.time()

args = commandArgs(trailingOnly=TRUE)
if (!length(args)==7) {
  stop("Seven arguments must be supplied (input file name for inputed traing data csv,
        input file name for imputed testing data csv, 
       split ration value (0..1), seed value,
       output file name for Kaggle result submission csv)", call.=FALSE)
}

fname_training_set <- args[1]
fname_testing_set <- args[2]
n.rounds <- args[3]
n.depth <- args[4]
n.alpha <- args[5]
n.lambda <- args[6]
fname_kaggle_submission <- args[7]

# regression modeller - xgboost
# ref.: http://xgboost.readthedocs.io/en/latest/R-package/xgboostPresentation.html
# https://github.com/dmlc/xgboost/blob/master/doc/parameter.md
# https://cran.r-project.org/web/packages/xgboost/vignettes/xgboostPresentation.html
# https://www.kaggle.com/michaelpawlus/springleaf-marketing-response/xgboost-example-0-76178/code
xgboostRegressionModeller <- function (df.train, df.test, formula2verify,
                                       nrounds=50, depth=14, alpha = 0.0001, lambda = 1) {
    print(paste0("Running xgboost linear modeller"))
    feature.names <- names(df.train)[2:ncol(df.train)-1]
    # names(train)  # 1934 variables
    
    print(paste0("assuming text variables are categorical & replacing 
                 them with numeric ids\n"))
    for (f in feature.names) {
        if (class(train[[f]])=="character") {
            levels <- unique(c(df.train[[f]], df.test[[f]]))
            df.train[[f]] <- as.integer(factor(df.train[[f]], levels=levels))
            df.test[[f]]  <- as.integer(factor(df.test[[f]],  levels=levels))
        }
    }
    
    set.seed(825)
    split <- sample.split(df.train$TARGET, SplitRatio = 0.8)
    
    # Create training and testing sets
    qualityTrain <- subset(df.train, split == TRUE)
    qualityVal <- subset(df.train, split == FALSE)
    
    
    # make training matrix
    dtrain <- xgb.DMatrix(data.matrix(qualityTrain[,feature.names]), 
                          label=qualityTrain$TARGET)
    
    # make validation matrix
    dval <- xgb.DMatrix(data.matrix(qualityVal[,feature.names]), 
                        label=qualityVal$TARGET)
    
    watchlist <- list(eval = dval, train = dtrain)
    
    param <- list(  objective           = "reg:linear", 
                    booster             = "gblinear",
                    eta                 = 0.001,
                    max_depth           = depth,  # changed from default of 6
                    subsample           = 0.6,
                    colsample_bytree    = 0.6,
                    eval_metric         = "rmse",
                    alpha = alpha, 
                    lambda = lambda
    )
    
    clf <- xgb.train(   params              = param, 
                        data                = dtrain, 
                        nrounds             = nrounds, # changed from 300
                        verbose             = 2, 
                        early.stop.round    = 10,
                        watchlist           = watchlist,
                        maximize            = TRUE)
    
    # predict
    f.predict <- predict(clf, data.matrix(df.test[,feature.names]))
    
    f.predict
}

strt<-Sys.time()

# read data
print(paste("Load data",Sys.time()))
train <- read.csv(fname_training_set)
test <- read.csv(fname_testing_set)

str(train)
str(test)

# basic split of test and train set by STARS provided or not
train1 <- subset(train, STARS == 0)
train2 <- subset(train, STARS > 0)

test1 <- subset(test, STARS == 0)
test2 <- subset(test, STARS > 0)

testIndex1 <- test1$INDEX
testIndex2 <- test2$INDEX

# prepare data for prediction
train1 <- select(train1, -INDEX, -STARS)
train2 <- select(train2, -INDEX)
test1 <- select(test1, -INDEX, -STARS)
test2 <- select(test2, -INDEX)

# fname_kaggle_submission <- args[7]

# train the models
print(paste("Train the models and make predictions",Sys.time()))
frm <- as.formula(TARGET ~ .)

predict1 <- xgboostRegressionModeller (train1, test1, frm,
                       nrounds = n.rounds, depth = n.depth, alpha = n.alpha, lambda = n.lambda)
predict2 <-xgboostRegressionModeller (train2, test2, frm,
                       nrounds = n.rounds, depth = n.depth, alpha = n.alpha, lambda = n.lambda)

# prepare submission
print(paste("Prepare submission file",Sys.time()))

#INDEX,P_TARGET
df1 <- data.frame(INDEX = testIndex1, P_TARGET = predict1)
df2 <- data.frame(INDEX = testIndex2, P_TARGET = predict2)
MySubmission <- rbind(df1,df2)
write.csv(MySubmission, fname_kaggle_submission, row.names=FALSE)

print(paste("Finished data submission",Sys.time()))
print(paste("Elapsed Time:",(Sys.time() - strt)))
##################################################
# That's all, folks!
##################################################