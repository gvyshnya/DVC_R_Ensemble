# Competition: https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/
# This is a file to perform 
# - ensemble prediction based on 3 models fitted (LR, GBM, and xgboost)
# - preparation of a Kaggle submission file for the ensemble prediction 
# It is intended to run from a command line in a batch mode, using the Rscript command below: 
# Rscript --vanilla code/ensemble.R code/config.R data/ensemble_submission.csv
# 2 arguments are required 
# - input configuration file in R (setup of the ensemble implemented as R code module), which has to have
#   the following variables assigned properly
#   - run_ensemble <- 1 # if set to 0, the ensemble will not predict
#   - model_predictions <- ["data/somefile.csv", "data/somefile2.csv", "data/somefile2.csv"]
#   - n.models <- 3 # or any valid number matching the number of actual model predictions in the ensemble

# - output file name for the result submission csv file (in a ready-for-Kaggle-upload format)

strt<-Sys.time()

args = commandArgs(trailingOnly=TRUE)
if (!length(args)==2) {
  stop("Two arguments must be supplied (input file name for ensemble configuration in R,
       output file name for Kaggle result submission csv)", call.=FALSE)
}

fname_config <- args[1]
fname_kaggle_submission <- args[2]

source(fname_config)

# for simplicity, ensemble will assign equal weights to each of the individual model predictions
# FIXME
prediction <- (p1_1 + p1_2 + p1_3)/n.models 

# prepare submission
print(paste("Prepare ensemble submission file",Sys.time()))

#INDEX,P_TARGET
MySubmission <- data.frame(INDEX = tIndex, P_TARGET = prediction)

write.csv(MySubmission, fname_kaggle_submission, row.names=FALSE)

print(paste("Finished data submission",Sys.time()))
print(paste("Elapsed Time:",(Sys.time() - strt)))
##################################################
# That's all, folks!
##################################################
