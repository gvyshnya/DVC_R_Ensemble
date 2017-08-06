# Competition: https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/
# This is a file to perform 
# - ensemble prediction based on 3 models fitted (LR, GBM, and xgboost)
# - preparation of a Kaggle submission file for the ensemble prediction 
# It is intended to run from a command line in a batch mode, using the Rscript command below: 
# Rscript --vanilla code/ensemble.R data/ensemble_submission.csv code/config.R
#
# 2 arguments are required
# - output file name for the result submission csv file (in a ready-for-Kaggle-upload format)
# - configuration file in R (setup of the ensemble implemented as R code module), which has to have
#   the following variables assigned properly
#   - run_ensemble <- 1 # if set to 0, the ensemble will not predict
#   - model_predictions <- ["data/somefile.csv", "data/somefile2.csv", "data/somefile2.csv"]
#   - n.models <- 3 # or any valid number matching the number of actual model predictions in the ensemble

strt<-Sys.time()

args = commandArgs(trailingOnly=TRUE)
if (!length(args)==2) {
  stop("Two arguments must be supplied (input file name for ensemble configuration in R,
       output file name for Kaggle result submission csv)", call.=FALSE)
}

fname_config <- args[1]
fname_kaggle_submission <- args[2]

source(fname_config)

# get ensemble components as defined in fname_config module
predictions <- c()
tIndex <- NULL # this is the vector of indexes of records in the test set - the same across all of the prediction files
for (prediction_fname in cfg_model_predictions) {
  df <- read.csv(prediction_fname)
  if (is.null(tIndex)) {
    # read Indexes of records in the training
    tIndex <- df$INDEX
  }
  pred <- df$P_TARGET  # this is specific to a particular project we tackle 
  
  # append the dataframe with a particular prediction to the vector of dataframes with individual predictions
  predictions <- c(predictions, pred)
}

#calculate ensemble prediction
ensemble_prediction <- NULL
total_weight <- 0

for (i in 1:length(predictions)) {
  model_weight <- cfg_model_weights[i]
  model_prediction <- predictions[i]
  if (is.null(ensemble_prediction)) {
    # the case of the first model prediction in the ensemble
    ensemble_prediction <- model_prediction * model_weight
  }
  else {
    ensemble_prediction <- ensemble_prediction + model_prediction * model_weight
  }
  total_weight <- total_weight + model_weight
}

# final ensemble prediction weightened
ensemble_prediction <- ensemble_prediction/total_weight

# prepare ensemble submission
print(paste("Prepare ensemble submission file",Sys.time()))

#INDEX,P_TARGET
MySubmission <- data.frame(INDEX = tIndex, P_TARGET = ensemble_prediction)

write.csv(MySubmission, fname_kaggle_submission, row.names=FALSE)

print(paste("Finished creating the ensemble submission",Sys.time()))
print(paste("Elapsed Time:",(Sys.time() - strt)))
##################################################
# That's all, folks!
##################################################
