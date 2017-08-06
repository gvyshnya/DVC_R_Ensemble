# This is a DVC-based script to manage machine-learning pipeline for a project per
# https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/

mkdir R_DVC_GITHUB_CODE
cd R_DVC_GITHUB_CODE

# clone the github repo with the code
git clone https://github.com/gvyshnya/DVC_R_Ensemble

# initialize DVC
$ dvc init

# import data
$ dvc import https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/download/wine.csv data/
$ dvc import https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/download/wine_test.csv data/

# run data pre-processing
$ dvc run Rscript --vanilla code/preprocessing.R data/wine.csv data/wine_test.csv data/training_imputed.csv data/testing_imputed.csv

# run LR model fit and forecasting
$ dvc run Rscript --vanilla code/LR.R data/training_imputed.csv data/testing_imputed.csv 0.7 825 data/submission_LR.csv code/config.R

# run GBM model fit and forecasting
$ dvc run Rscript --vanilla code/GBM.R data/training_imputed.csv data/testing_imputed.csv 5000 10 4 25 data/submission_GBM.csv code/config.R

# rum XGBOOST model fit and forecasting
$ dvc run Rscript --vanilla code/GBM.R data/training_imputed.csv data/testing_imputed.csv 1000 10 0.0001 1.0 data/submission_xgboost.csv code/config.R

# prepare ensemble submission
# Note: please make sure to edit your code/config.R to set up the references to the predictions from each model according
# to the names of output files on the steps above
$ dvc run Rscript --vanilla code/ensemble.R data/submission_ensemble.csv code/config.R



