# Overview
This repo contains R scripts that constitute the elements of the machine learning pipeline for the ML experiments to tackle the supervised-learning regression problem to predict vine sales per https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/

R scripts were originally developed by George Vyshnya back in 2016 as the above-mentioned completion was active. The scripts were then slightly modified in 2017 to demonstrate the potential of building repeatable and reusable production-ready ML pipelines for R-based applications, using the prominent Data Version Control (DVC) application (https://dataversioncontrol.com/). 

DVC is an open source tool for data science projects. It makes your data science projects reproducible by automatically building data dependency graph (DAG). Your code and the dependencies could be easily shared by Git, and data - through cloud storage (AWS S3, GCP) in a single DVC environment.

DVC is courtesy to Dmitry Petrov who is the principal developer and maintainer of DVC. He also developed the original tutorial (https://blog.dataversioncontrol.com/data-version-control-beta-release-iterative-machine-learning-a7faf7c8be67) to walk you through applying DVC to building a solid process and pipeline for Python-based ML projects.

While working on DVC pipeline for this project, the respective DVC tutorial for R-based projects was used. Such a tutorial (https://blog.dataversioncontrol.com/r-code-and-reproducible-model-development-with-dvc-1507a0e3687b) is courtesy to Marija Ilić.

# Dependencies
In order to try the materials of this repo in your environment, the following pre-requisites should be installed on your machine
- Python 3 runtime environment for your OS (it is required to run DVC commands in the batch files)
- DVC itself (see https://dataversioncontrol.com/, Installation section on how to install DVC on your machine)
- Latest version of R runtime environment 
- Latest version of git command-line client application

# Technical Challenges
The technical challenges of building DVC-backed ML pipeline for this project were to meet business requirements below
- Ability to conditionally trigger execution of 3 different ML prediction models 
- Ability to conditionally trigger model ensemble prediction based on predictions of those 3 individual models
- Ability to specify weights of each of the individual model predictions in the ensemble

The next section below will explain how these challenges are addressed in the design of ML pipeline for this project.

# ML Pipeline
ML pipeline for this project is presented in the diagram below

[https://github.com/gvyshnya/DVC_R_Ensemble/blob/master/logical_workflow.png]

As you can see, the essential implementation of the solution is as follows
- _preprocessing.R_ handles all aspects of data manipulations and pre-processing (reading training and testing data sets, removing outliers, imputing NAs etc.) as well as storing refined training and testing set data as files to reuse by model scripts
- 3 model scripts implement training and forecasting algorithms for each of the models selected for this project (_LR.R, GBM.R, xgboost.R_)
- _ensemble.R_ is responsible for the weighted ensemble prediction and the final output of the Kaggle submission file
- _config.R_ is responsible for all of the conditional logic switches needed in the pipeline (it is included as a source to all of modelling and ensemble prediction scripts, to get this done)

# Files in This Repo 
You will find the following files and folders in this repo

- _code_ folder contains R scripts used in this solution
- _dvc.bat_ is a Windows bat file that implements DVC-based pipeline to orchestrate different steps of the ML pipeline for this project
- _Readme.md_ – this readme document

Subsections below provide more details on every technical asset mentioned above.

## R Script Files
_code_ folder with R script files contains the following elements

- requirements.R
- pre-processing.R
- LR.R
- GBM.R
- xgboost.R
- ensemble.R
- config.R

The role and method of use of each of the R script files is described below.

### requirements.R
This script will install necessary packages into your local R environment. 

**Notes:**

- You will have to run this job only once in case you need to install packages that are used in this project 
- This file is not the part of the ML pipeline for this project technically – you can consider it to be your ‘installer’ for it, if you will

### pre-processing.R
This file is responsible for several initial steps of the ML pipeline for this project

- pre-processing of the initial training and testing data sets (imputation of NAs, elimination of outliers from the training set)
- saving pre-processed training and testing data sets as new csv files for future re-use by ML models

**Note**: due to the nature of the data for this ML prediction competition, there was no need for additional feature engineering. Therefore there is no a dedicated pipeline steps managing it.

This script can be launched from a command line with the command as follows

`Rscript --vanilla code/pre-processing.R "Str1" "Str2" "Str4" "Str4"`

Where

- _Str1_ - input file name for raw traing data csv (by default, the DVC pipeline script will download it to 'data/wine.csv' - see below)
- _Str2_ - input file name for raw testing data csv (by default, the DVC pipeline script will download it to 'data/wine_test.csv' - see below)
- _Str3_ - output file name for imputed training data csv (for example, 'data/train_imputed.csv')
- _Str4_ - output file name for imputed testing data csv (for example, 'data/test_imputed.csv')

### LR.R
This file implements the following capabilities

- Train and fit the Linear Regression (LR) model  for predictions
- Predict test values on the test set, using the trained LR model
- Output the prediction results as a Kaggle submission file of a format specified by the requirements to the completion per https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/

This script can be launched from a command line with the command as follows

`Rscript --vanilla "code/LR.R" "Str1" "Str2" "Float1" "Int1" "Str3" code/config.R`

Where 
- _Str1_ – relative path to the input file name for imputed training data csv (recommended default value: "_data/training_imputed.csv_") – such file is generated by _pre-processing.R_ on the earlier step of the ML pipeline
- _Str2_ - input file name for imputed testing data csv (recommended default value: "data/testing_imputed.csv") – such file is generated by pre-processing.R on the earlier step of the ML pipeline
- _Float1_ – the number (in 0..1 interval) to specify the split ratio of the training set on true training vs. validation parts (recommended value is 0.7)
- _Int1_ – the integer value to set the value of seed, to ensure reproducible modelling results (it can be any non-negative integer number, for example 825)
- _Str3_ – relative path to the result submission csv file (in a ready-for-Kaggle-upload format); recommended value is "_data/submission_LR.csv_"
- _code/config.R_ - the configuration file of the solution in a format of R script module (please use _config.R_ provided)

**Notes:** 
- Training and predictions are performed in "cluster-then-predict" framework since the observations in both the training and testing sets allow for clear clustering the data by a meaningful business factor (wines starred by experts and wines not starred by any of the experts)
- Cross-validation efforts had been taken to tune the parameters of LR model itself as well as to prove cluster-then-predict setup yields better prediction accuracy vs. using the entire training and testing sets (however, the cross-validation scripts are not the parts of ML pipeline directly, and thus they are not the part of this repo)
- Please make sure to specify the same name of the relative path to the result submission csv file for LR model in the ensemble setup section of _config.R_
- Please refer below as for manual editing config.R to tweak the run-time parameters for the ML solution/pipeline

### GBM.R
This file implements the following capabilities

- Train and fit the GBM model  for predictions
- Predict test values on the (imputed) test set data, using the trained GBM model
- Output the prediction results as a Kaggle submission file of a format specified by the requirements to the completion per https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/

This script can be launched from a command line with the command as follows

`Rscript --vanilla code/GBM.R "Str1" "Str2" "Int1" "Int2" "Int3" "Int4" "Str3" code/config.R`

Where
- _Str1_ - input file name for imputed training data csv (for example, 'data/train_imputed.csv' - it should be located where preprocessing.R output it)
- _Str2_ - input file name for imputed testing data csv (for example, 'data/test_imputed.csv' - it should be located where preprocessing.R output it)
- _Int1_ - number of trees to generate in GBM search (integer)
- _Int2_ - depth of GBM Search (integer)
- _Int3_ - number of folds in the internal GBM cross-validation (integer)
- _Int4_ - minimum number of observations in a bucket in order to make another tree split in GBM search (integer)
- _Str3_ - output file name for the result submission csv file (in a ready-for-Kaggle-upload format), for example 'output/submission_gbm.csv'
- the last parameter is the configuration file of the solution implemented as an R script (this is 'code/config.R' by default)

**Notes:**

- Training and predictions are performed in “cluster-then-predict” framework since the observations in both the training and testing sets allow for clear clustering the data by a meaningful business factor (wines starred by experts and wines not starred by any of the experts)
- Cross-validation efforts had been taken to tune the parameters of GBM model itself as well as to prove cluster-then-predict setup yields better prediction accuracy vs. using the entire training and testing sets (however, the cross-validation scripts are not the parts of ML pipeline directly, and thus they are not the part of this repo)
- Please refer below as for manual editing config.R to tweak the run-time parameters for the ML solution/pipeline
- Please review http://www.inside-r.org/packages/cran/gbm/docs/gbm for more details on each of the GBM-specific int parameters above

### xgboost.R
This file implements the following capabilities

- Train and fit the xgboost model  for predictions
- Predict test values on the (imputed) test set data , using the trained xgboost model
- Output the prediction results as a Kaggle submission file of a format specified by the requirements to the completion per https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/

This script can be launched from a command line with the command as follows

`Rscript --vanilla code/GBM.R "Str1" "Str2" "Int1" "Int2" "Float1" "Float2" "Str3" code/config.R`

Where
- _Str1_ - input file name for imputed training data csv (for example, 'data/train_imputed.csv' - it should be located where preprocessing.R output it)
- _Str2_ - input file name for imputed testing data csv (for example, 'data/test_imputed.csv' - it should be located where preprocessing.R output it)
- _Int1_ - number of rounds in the xgboost search (integer)
- _Int2_ - depth of search (integer)
- _Float1_ - alpha, one of the linear booster-specific parameters (float)
- _Float2_ - lambda, one of the linear boster-specific parameters (float)
- _Str3_ - output file name for the result submission csv file (in a ready-for-Kaggle-upload format), for example 'output/submission_xgboost.csv'
- the last parameter is the configuration file of the solution implemented as an R script (this is 'code/config.R' by default)

**Notes:**
 
- Training and predictions are performed in “cluster-then-predict” framework since the observations in both the training and testing sets allow for clear clustering the data by a meaningful business factor (wines starred by experts and wines not starred by any of the experts)
- Cross-validation efforts had been taken to tune the parameters of xgboost model itself as well as to prove cluster-then-predict setup yields better prediction accuracy vs. using the entire training and testing sets (however, the cross-validation scripts are not the parts of ML pipeline directly, and thus they are not the part of this repo)
- Please refer below as for manual editing config.R to tweak the run-time parameters for the ML solution/pipeline
- Please review http://xgboost.readthedocs.io/en/latest/R-package/xgboostPresentation.html for more details on xgboost-specific parameters

### ensemble.R
This script will utilize individual predictions saved by individual MLs in this project (LR, GBM, xgboost) to prepare ensemble submissions in a format of a Kaggle Submission file specified in requirements to https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/

_ensemble.R_ will rely on the configuration settings in _config.R_ on the conditional logic as for

- Preparing ensemble submission (or not)
- Specifying weights of every model prediction in the ensemble

This script can be launched from a command line with the command as follows

`Rscript --vanilla code/ensemble.R "Str1" code/config.R`

Where
- _Str1_ - output file name for the result submission csv file (in a ready-for-Kaggle-upload format)
- configuration file in R (setup of the ensemble implemented as R code module) - the default version provided in _code/config.R_

### config.R
This file is not intended to run from a command line (unlike the rest of the R scripts in the project).
It is de-facto a configuration file for entire solution (although the configuration itself is specified as R statements/variable assignments). This file is included as a source file to all of the other R scripts mentioned above. Thus the respective parameters (assigned as R variables) will be retrieved by the runnable scripts, and the conditional logic there will be triggered respectively.

## DVC Batch File
TBD

