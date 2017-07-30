# Competition: https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/
# This is a file to perform 
# - GBM model training
# - predition on the imputed testing set, using the fitted GBM model (for regression problem, 
#   gaussian distribution used in GBM)
# - preparation of a Kaggle submission file 
# It is intended to run from a command line in a batch mode, using the Rscript command below: 
# Rscript --vanilla code/GBM.R data/train_imputed.csv data/test_imputed.csv 0.7 826 data/submission.csv
# 7 arguments are required 
# - input file name for imputed training data csv,
# - input file name for imputed testing data csv
# - number of trees to generate in GBM search (integer)
# - depth of GBM Search (integer)
# - number of folds in the internal GBM cross-validation (integer)
# - minimum number of observations in a bucket in order to make another tree split in GBM search (integer)
# - output file name for the result submission csv file (in a ready-for-Kaggle-upload format)
# 
# Note: please refer to http://www.inside-r.org/packages/cran/gbm/docs/gbm for more details
#       on each of the GBM-specific int parameters above

library(caret)
library(plyr)
library(dplyr)
library(caTools)
library(gbm)

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
n.trees <- args[3]
n.depth <- args[4]
n.folds <- args[5]
n.minobservationbucket <- args[6]
fname_kaggle_submission <- args[7]

# regression modeller - GBM
# ref.: http://www.inside-r.org/packages/cran/gbm/docs/gbm
gbmRegressionModeller <- function (df.train, df.test, formula2verify, ntrees,
                                   depth, nfolds, minobservations) {
    print(paste0("Running gbm gaussian modeller"))
    gbm1 <-
        gbm(formula2verify,              # formula
            data=df.train,               # training dataset
            distribution="gaussian",     # (squared error) - used in regression
            n.trees=ntrees,              # number of trees
            shrinkage=0.001,             # shrinkage or learning rate,
                                         # 0.001 to 0.1 usually work
            interaction.depth=depth,     # 1: additive model, 2: two-way interactions, etc.
            bag.fraction = 0.5,          # subsampling fraction, 0.5 is probably best
            train.fraction = 0.5,        # fraction of data for training,
                                         # first train.fraction*N used for training
            n.minobsinnode = minobservations, # minimum total weight needed in each node
            cv.folds = nfolds,           # do n-fold cross-validation
            keep.data=TRUE,              # keep a copy of the dataset with the object
            verbose=FALSE)               # don't print out progress
    
    # check performance using an out-of-bag estimator
    # OOB underestimates the optimal number of iterations
    best.iter <- gbm.perf(gbm1,method="OOB")
    print(best.iter)
    
    # check performance using a 50% heldout test set
    best.iter <- gbm.perf(gbm1,method="test")
    print(best.iter)
    
    # check performance using 5-fold cross-validation
    best.iter <- gbm.perf(gbm1,method="cv")
    print(best.iter)
    
    # plot the performance # plot variable influence
    summary(gbm1,n.trees=1)         # based on the first tree
    summary(gbm1,n.trees=best.iter) # based on the estimated best number of trees
    
    # compactly print the first and last trees for curiosity
    print(pretty.gbm.tree(gbm1,1))
    print(pretty.gbm.tree(gbm1,gbm1$n.trees))
    
    # predict on the new data using "best" number of trees
    # f.predict generally will be on the canonical scale (logit,log,etc.)
    f.predict <- predict(gbm1,df.test,best.iter)
    
    f.predict
}

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

# train the models
print(paste("Train the models and make predictions",Sys.time()))
frm <- as.formula(TARGET ~ .)

predict1 <- gbmRegressionModeller(train1, test1, frm, 
                  ntrees = n.trees, depth = n.depth, nfolds = n.folds, 
                  minobservations = n.minobservationbucket)

predict2 <- gbmRegressionModeller(train2, test2, frm, 
                  ntrees = n.trees, depth = n.depth, nfolds = n.folds, 
                  minobservations = n.minobservationbucket)

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