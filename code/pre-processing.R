# This file manages pre-processing of raw traing and testing data sets for the 
# Kaggle competion per https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/
# It is intended to run from a command line in a batch mode, using the Rscript command below: 
# Rscript --vanilla code/pre-processing.R data/wine.csv data/wine_test.csv data/train_imputed.csv data/test_imputed.csv 
# 4 arguments are required 
# - input file name for raw traing data csv
# - input file name for raw testing data csv, 
# - output file name for imputed training data csv,
# - output file name for imputed testing data csv


library(caret)
library(plyr)
library(dplyr)
library(mice)

args = commandArgs(trailingOnly=TRUE)
if (!length(args)==4) {
  stop("Four arguments must be supplied (input file name for traing data csv,
        input file name for testing data csv, 
       output file name for imputed training data csv,
       output file name for imputed testing data csv)", call.=FALSE)
} 


strt<-Sys.time()

fname_training_set <- args[1]
fname_testing_set <- args[2]
fname_train_imputed <- args[3]
fname_test_imputed <- args[4]

# read data
print(paste("Load data",Sys.time()))
train <- read.csv(fname_training_set)
test <- read.csv(fname_testing_set)

str(train)
str(test)
nrow(train)
nrow(test)

#remove outliers from the training set
print(paste("Remove outliers from the training set",Sys.time()))

# outliers in training set:
# -- Acid Index = 4
# -- Alcohol: < min(test$Alcohol, na.rm=TRUE); > max(test$Alcohol, na.rm=TRUE)
# -- FixedAcidity: > max(train$FixedAcidity, na.rm=TRUE)
# -- VolatileAcidity: > max(train$VolatileAcidity, na.rm=TRUE)
train <- subset(train, AcidIndex > 4)

min.test.alcohol <- min(test$Alcohol, na.rm=TRUE)
max.test.alcohol <- max(test$Alcohol, na.rm=TRUE)
train <- subset(train, Alcohol >= min.test.alcohol & 
                    Alcohol <= max.test.alcohol)

max.test.fixed_acidity <- max(test$FixedAcidity, na.rm=TRUE)
train <- subset(train, FixedAcidity <= max.test.fixed_acidity)

max.test.volatile_acidity <- max(test$VolatileAcidity, na.rm=TRUE)
train <- subset(train, VolatileAcidity <= max.test.volatile_acidity)

nrow(train)

# do data preprocessing
print(paste("Start data pre-processing",Sys.time()))
trainTargets <- train$TARGET
trainLimited <- select(train, -TARGET)
testLimited <- select(test, -TARGET)

# combine test and training data into one data set for ease of manipulation
all <- rbind(trainLimited,testLimited)
end_trn <- nrow(trainLimited)
end <- nrow(all)
end_trn
end

# detach INDEX
indexAll <- all$INDEX
all <- select(all, -INDEX)

# impute NA in STARS with a new category value
stars_not_provided <- 0
all$STARS[is.na(all$STARS)] <- stars_not_provided

starsAll <- all$STARS
all <- select(all, -STARS)

# apply mice imputation to NA values in variables below:
#  Chlorides, FreeSulfurDioxide, TotalSulfurDioxide, pH
#  Sulphates, Alcohol

# impute missing data
df.samples <- 8 
tempData <- mice(all,m=df.samples,maxit=5,meth='pmm',seed=825)

# get individual imputation sample data frames
all.1 <- complete(tempData, 1)
all.2 <- complete(tempData, 2)
all.3 <- complete(tempData, 3)
all.4 <- complete(tempData, 4)
all.5 <- complete(tempData, 5)
all.6 <- complete(tempData, 6)
all.7 <- complete(tempData, 7)
all.8 <- complete(tempData, 8)

# do imputation of NA values by taking avg values from the sample df
all$Chlorides <- (all.1$Chlorides + all.2$Chlorides + all.3$Chlorides +
                    all.4$Chlorides + all.5$Chlorides + all.6$Chlorides +
                    all.7$Chlorides + all.8$Chlorides) / df.samples

all$FreeSulfurDioxide <- (all.1$FreeSulfurDioxide + all.2$FreeSulfurDioxide + 
            all.3$FreeSulfurDioxide + all.4$FreeSulfurDioxide + 
            all.5$FreeSulfurDioxide + all.6$FreeSulfurDioxide +
            all.7$FreeSulfurDioxide + all.8$FreeSulfurDioxide) / df.samples

all$TotalSulfurDioxide <- (all.1$TotalSulfurDioxide + all.2$TotalSulfurDioxide + 
            all.3$TotalSulfurDioxide + all.4$TotalSulfurDioxide + 
            all.5$TotalSulfurDioxide + all.6$TotalSulfurDioxide +
            all.7$TotalSulfurDioxide + all.8$TotalSulfurDioxide) / df.samples

all$pH <- (all.1$pH + all.2$pH + 
            all.3$pH + all.4$pH + 
            all.5$pH + all.6$pH +
            all.7$pH + all.8$pH) / df.samples

all$Sulphates <- (all.1$Sulphates + all.2$Sulphates + 
            all.3$Sulphates + all.4$Sulphates + 
            all.5$Sulphates + all.6$Sulphates +
            all.7$Sulphates + all.8$Sulphates) / df.samples

all$Alcohol <- (all.1$Alcohol + all.2$Alcohol + 
            all.3$Alcohol + all.4$Alcohol + 
            all.5$Alcohol + all.6$Alcohol +
            all.7$Alcohol + all.8$Alcohol) / df.samples

all$ResidualSugar <- (all.1$ResidualSugar + all.2$ResidualSugar + 
                    all.3$ResidualSugar + all.4$ResidualSugar + 
                    all.5$ResidualSugar + all.6$ResidualSugar +
                    all.7$ResidualSugar + all.8$ResidualSugar) / df.samples

# output pre-processed data frames with imputed values
print(paste("Save imputed data frames as csv files",Sys.time()))

# reconstruct training and testing sets with imputed values
all$INDEX <- indexAll
all$STARS <- starsAll

train <- all[1:end_trn,]
train$TARGET  <- trainTargets
test <- all[(end_trn+1):end,]

# serialize imputed data frames as csv files for further use in models
write.csv(train, fname_train_imputed, row.names=FALSE)
write.csv(test, fname_test_imputed, row.names=FALSE)

print(paste("Finished data pre-processing",Sys.time()))
print(paste("Elapsed Time:",(Sys.time() - strt)))
##################################################
# That's all, folks!
##################################################