# This is a DVC-based script to manage machine-learning pipeline for a project per
# https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/

mkdir R_DVC_GITHUB_CODE
cd R_DVC_GITHUB_CODE

# TODO: submit your repo details
# git clone https://github.com/Zoldin/R_AND_DVC

# initialize DVC
$ dvc init

# import data
$ dvc import https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/download/wine.csv data/
$ dvc import https://inclass.kaggle.com/c/pred-411-2016-04-u3-wine/download/wine_test.csv data/



# Dmitry's suggestions on conditional logic and question answers

## Original Questions

## 1. If your ML project uses more then one prediction model, can we conditionally trigger which one we use in a current run 
##  (provided every ML algorithm implemented in a separate R or .py file) ?
## 2. If you like to build an ensemble prediction based on the weighted forecasts from each of individual models/algorithms, is there a way 
##   to switch ensemble calculation on/off in the pipeline?
## 3. Is there a way to specify certain arguments in a configuration file to read by one of the steps in DVC job/process ?

## (1) [Conditional trigger] interesting question... posible solution:
##      DVC connects DAG edges by input\output filenames.. The same output filename could be used for two models:

## $ dvc run python train1.py data/input.csv data/model.p
## $ dvc run python evaluate.py data/model.p data/evel.txt
## # change some code
## $ dvc run repro data/eval.txt # repro for the model1
## # Change model to #2
## $ dvc remove data/model.p # you can try to skip this command, it might work
## $ dvc run python train2.py data/input.csv data/model.p # change model / modify DAG
## $ dvc run repro data/eval.txt # repro for the model2, it reuses model1 pipeline
## # Revert back
## $ dvc run python train1.py data/input.csv data/model.p # change model back to #1
## $ dvc run repro data/eval.txt # repro for the model1

## (2) You should probably try approach (1) with pipeline changing. In theory, you can replace a sequence of steps by another sequence of steps. 
##     This is actually very interesting topic and a meaningful code example can be a good foundation for a solid blog post.
## (3) the answer is no, but you can supply the config file as a script parameter (code) and DVC will include the config file into DAG. 
##     So, any change in the config file will be considered as a dependency change and accordingly the code rerunning.