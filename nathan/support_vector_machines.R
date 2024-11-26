library(e1071)
library(dplyr)
library(missForest)
library(readr)


test = read_csv("test.csv")
train = read_csv("train.csv")
# data_dictionary = read_csv("data_dictionary.csv")

# Cleaning
train_clean = train %>% select(-ends_with("Season")) 
train_clean$sii = factor(train_clean$sii)

colnames(train_clean) = gsub("-", "_", colnames(train_clean))


train_clean$sii <- factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing"))
train_clean$sii[is.na(train_clean$sii)] <- "Missing"

categorical_vars = train_clean %>% select(where(is.factor) | where(is.character) | 'sii')

quantitative_vars = train_clean %>% select(where(is.numeric) | 'sii')


# Identify columns that contain 'PCIAT' in their names but exclude 'PCIAT_PCIAT_Total'
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns]) # Extract these columns and add them to the categorical variables







