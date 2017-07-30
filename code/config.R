# Competition: https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/
# This is a configuration file to the entire solution 

# LR.R specific settings
cfg_run_LR <- 1 # if set to 0, LR model will not fit, and its prediction will not be calculated in the batch mode

# GMB.R specific settings
cfg_run_GBM <- 1 # if set to 0, GBM model will not fit, and its prediction will not be calculated in the batch mode

# xgboost.R specific settings

# ensemble.R specific settings
cfg_run_ensemble <- 1 # if set to 0, the ensemble will not predict, and ensemble prediction will not be created

# ensemble components
cfg_model_predictions <- c("data/submission_LR.csv", "data/submission_GBM.csv", "data/submission_XGBOOST.csv")
# element weights mapped to the cfg_model_predictions elements above
cfg_model_weights <- c(1,1,1) # weights of predictions of the models in the ensemble
