
library(readr)       
library(dplyr)       
library(caret)       
library(ggplot2)
library(parsnip)
library(purrr)
library(discrim)
library(yardstick)

train = read_csv("train.csv")
# ---------------------------------------------------------------------------------------------------------------------- #

# Data Manipulation:
colnames(train) = gsub("-", "_", colnames(train)) # Replacing hyphens because R can't handle those
train_clean = train %>% select(-contains("Season"))
train_clean$sii = factor(train_clean$sii) # Making sure `sii` is a factor with 4 levels (plus extra level for NAs later)


train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing")) # Replacing NAs with new level
train_clean$sii[is.na(train_clean$sii)] = "Missing"


categorical_vars = train_clean %>%
  select(where(is.factor) | where(is.character))  # Select categorical variables including 'sii'
# Identify columns that contain 'PCIAT' in their names but excluding 'PCIAT_PCIAT_Total'
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns])

categorical_vars = categorical_vars %>%
  mutate(across(everything(), ~ replace(., is.na(.), "Missing")))

quantitative_vars = train_clean %>%
  select(where(is.numeric))  # Select quantitative variables including 'sii'

quantitative_vars_imputed = quantitative_vars %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

train_data = bind_cols(categorical_vars, quantitative_vars_imputed)
# ---------------------------------------------------------------------------------------------------------------------- #

# Linear Discriminant Analysis

lda_spec = discrim_linear()
lda_recipe = recipe(sii~., data = quantitative_vars_imputed)
  
#lda_fit = lda_spec |> add_recipe(lda_recipe |> 

lda_fit |> pluck("fit")
