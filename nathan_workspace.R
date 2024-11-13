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


test = read_csv("test.csv")
train = read_csv("train.csv")
# data_dictionary = read_csv("data_dictionary.csv")

# PCIAT-PCIAT_Total 
# PCIAT cols can be response
# Non-binary categorical response: 4 possible outcomes


# Multinomial Logistic Regression
  
train_modified = train %>%
  mutate(
    impairment_severity = case_when(
      `PCIAT-PCIAT_Total` >= 0 & `PCIAT-PCIAT_Total` <= 30 ~ "None",
      `PCIAT-PCIAT_Total` >= 31 & `PCIAT-PCIAT_Total` <= 49 ~ "Mild",
      `PCIAT-PCIAT_Total` >= 50 & `PCIAT-PCIAT_Total` <= 79 ~ "Moderate",
      `PCIAT-PCIAT_Total` >= 80 & `PCIAT-PCIAT_Total` <= 100 ~ "Severe"
      ))



# K-Nearest Neighbors

# Regression Spline

# Random Forest

# Support Vector Machine

# Linear Discriminant Analysis / Quadratic Discriminant Analysis ??

# Include model validation?

