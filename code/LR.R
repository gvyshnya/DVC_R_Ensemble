# Competition: https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/
# This is a file to perform 
# - Linear Regression (LR) model training
# - predition on the imputed testing set, using the fitted LR model
# - preparation of a Kaggle submission file 
# It is intended to run from a command line in a batch mode, using the Rscript command below: 
# Rscript --vanilla code/LF.R data/train_imputed.csv data/test_imputed.csv 0.7 826 data/submission.csv config.R
# 6 arguments are required
# - input file name for imputed training data csv,
# - input file name for imputed testing data csv
# - split ratio of the training set on true training vs. validation parts
# - seed value
# - output file name for the result submission csv file (in a ready-for-Kaggle-upload format)
# - the configuration file of the solution in a format of R script module (please use config.R provided)
#
# Note: in the solution setup, this script will be located under the relative path of 'code/LF.R'

library(caret)
library(plyr)
library(dplyr)
library(caTools)

strt<-Sys.time()

args = commandArgs(trailingOnly=TRUE)
if (!length(args)==6) {
  stop("Five arguments must be supplied (input file name for inputed traing data csv,
        input file name for imputed testing data csv, 
       split ration value (0..1), seed value,
       output file name for Kaggle result submission csv,
       configuration R file for the project (use config.R supplied with this app))", call.=FALSE)
} 



fname_training_set <- args[1]
fname_testing_set <- args[2]
split_ratio <- args[3]
seed_value <- args[4]
fname_kaggle_submission <- args[5]
fname_config <- args[6]

source(fname_config) # import the config file as R source as it is the R source code indeed

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

# further split training sets into pure training and validation sets
set.seed(seed_value)

spl1 = sample.split(train1$TARGET, split_ratio)
train1.tr <- subset(train1, spl1==TRUE)
train1.val <- subset(train1, spl1==FALSE)

set.seed(seed_value)
spl2 = sample.split(train2$TARGET, split_ratio)
train2.tr <- subset(train2, spl2==TRUE)
train2.val <- subset(train2, spl2==FALSE)

# train the models
print(paste("Train the models",Sys.time()))
frm <- as.formula(TARGET ~ .)

# those formula contain important variables only, 
# based on initial frm performance
frm.starred <- as.formula(TARGET ~ VolatileAcidity + Chlorides +
                FreeSulfurDioxide + Alcohol + LabelAppeal + AcidIndex + STARS)
frm.not_starred <- as.formula(TARGET ~ VolatileAcidity + FreeSulfurDioxide +
                    TotalSulfurDioxide + Sulphates + AcidIndex)

model1 <- lm(frm.not_starred, data = train1.tr)
summary(model1)
SSE1 <- sum(model1$residuals^2)
SSE1

model2 <- lm(frm.starred, data = train2.tr)
summary(model2)
SSE2 <- sum(model2$residuals^2)
SSE2

# Make predictions on validation data
print(paste("Make predictions on validation sets",Sys.time()))
set.seed(seed_value)
predict1.val <- predict(model1, newdata = train1.val)
str(predict1.val)
summary(predict1.val)
predict2.val <- predict(model2, newdata = train2.val)
str(predict2.val)
summary(predict2.val)

# quantify prediction accuracy by computing the R-squared value for our test set
# the formula for R-squared is 1 minus the sum of squared errors divided
# by the total sum of squares :
#      R2 = 1 - (SSE/SST)
print(paste("Quantify accuracy on validation sets",Sys.time()))
SSETest1 <- sum ((train1.val$TARGET - predict1.val)^2)
SSTTest1 <- sum ((train1.val$TARGET - mean(train1.tr$TARGET))^2)
R2_1 <- 1 - (SSETest1/SSTTest1)
R2_1

SSETest2 <- sum ((train2.val$TARGET - predict2.val)^2)
SSTTest2 <- sum ((train2.val$TARGET - mean(train2.tr$TARGET))^2)
R2_2 <- 1 - (SSETest2/SSTTest2)
R2_2

# Make final predictions
set.seed(seed_value)
print(paste("Make final predictions",Sys.time()))
predict1 <- predict(model1, newdata = test1)
str(predict1)
summary(predict1)
predict2 <- predict(model2, newdata = test2)
str(predict2)
summary(predict2)

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