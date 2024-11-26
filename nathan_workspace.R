library(readr)
library(recipes)
library(yardstick)
library(parsnip)
library(purrr)
library(discrim)
library(rsample)
library(workflows)
library(tune)
library(dplyr)
library(tidyverse)
library(rpart)
library(leaps)
library(glmnet)
library(pls)
library(workflowsets)
library(nnet) # multinom logistic reg
library(mice)
library(naniar)
library(mitools)
library(e1071)

# K-Nearest Neighbors (Eddie)
# Random Forest (Kwan)
# Neural Networks?


test = read_csv("test.csv")
train = read_csv("train.csv")
# data_dictionary = read_csv("data_dictionary.csv")

# Cleaning
train_clean = train %>% select(-ends_with("Season")) 
train_clean$sii = factor(train_clean$sii)

colnames(train_clean) = gsub("-", "_", colnames(train_clean))

# Replacing NA with "Missing" level
# train_clean$sii <- addNA(train_clean$sii)
#levels(train_clean$sii)[is.na(levels(train_clean$sii))] <- "Missing"

# Replacing NA with the mode level
# mode_value <- names(which.max(table(train_clean$sii)))
# train_clean$sii[is.na(train_clean$sii)] <- mode_value

# end



# Linear Discriminant Analysis: 



# Support Vector Machines




