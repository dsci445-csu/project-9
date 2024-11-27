# All possible packages I am using for this project:
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
library(tidyr)
library(tidymodels)
library(kernlab)
library(leaps)
library(glmnet)
library(pls)
library(workflowsets)
library(nnet) # multinom logistic reg
library(mice)
library(naniar)
library(mitools)
library(e1071)
library(ggplot2)
library(caret)


# K-Nearest Neighbors (Eddie)
# Random Forest (Kwan)
# Neural Networks?


test = read_csv("test.csv")
train = read_csv("train.csv")
data_dictionary = read_csv("data_dictionary.csv")

train_clean = train %>% select(-ends_with("Season")) 
train_clean$sii = factor(train_clean$sii)

colnames(train_clean) = gsub("-", "_", colnames(train_clean))

train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing"))
train_clean$sii[is.na(train_clean$sii)] = "Missing"

train_clean$PreInt_EduHx_computerinternet_hoursday[is.na(train_clean$PreInt_EduHx_computerinternet_hoursday)] <- "Missing"



train_clean = train_clean[!is.na(train_clean$PCIAT_PCIAT_Total), ]

plot1 = ggplot(data = train_clean, aes(x = sii, fill = `PreInt_EduHx_computerinternet_hoursday`)) + 
  geom_bar(stat = "count") + 
  labs(title = "Severity Impairment Index", x = "Severity Level", y = "Count", fill = "Level of Time Spent on Computer") +
  theme_minimal()
plot1

plot2 = ggplot(data = train_clean, aes(x = PCIAT_PCIAT_Total, y = sii, color = `PreInt_EduHx_computerinternet_hoursday`)) + 
  geom_point(position = "jitter", alpha = 0.5) + 
  labs(title = "Severity Impairment Index", y = "Severity Level", x = "Parent-Child Internet Addiction Test Total", color = "Level of Time Spent on Computer") + 
  theme_minimal()
plot2

# Linear Discriminant Analysis: 


# Support Vector Machine:




