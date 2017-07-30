#!/usr/bin/Rscript

# Competition: https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/
# This is the file to install all R packages needed by ML parts of this project
# In case your R environment has any of those packages already installed, it will be skipped during 
# the execution of this file
#
# Note: you should execute this script once, before you run the elements of ML pipeline of this project

pkgs <- c("caret", "plyr", "dplyr", "mice", "caTools", "gbm", "xgboost") 
for (pkg in pkgs) {
  if (! (pkg %in% rownames(installed.packages()))) { 
    install.packages(pkg) 
  }
}
rm(pkgs)
rm(pkg)