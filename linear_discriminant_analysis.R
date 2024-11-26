library(e1071)
library(dplyr)
library(missForest)


test = read_csv("test.csv")
train = read_csv("train.csv")
# data_dictionary = read_csv("data_dictionary.csv")

# Cleaning
train_clean = train %>% select(-ends_with("Season")) 
train_clean$sii = factor(train_clean$sii)

colnames(train_clean) = gsub("-", "_", colnames(train_clean))

# Replacing NA with the mode level
mode_value <- names(which.max(table(train_clean$sii)))
train_clean$sii[is.na(train_clean$sii)] <- mode_value

# Data Imputation:

# Define custom methods for each variable
methods <- make.method(train_clean)

# Set 'polyreg' for sii
methods["sii"] <- "polyreg"

# Set other methods (e.g., 'pmm' for numerical variables)
methods[names(train_clean) != "sii"] <- "pmm"

# Perform imputation
imputed_data <- mice(train_clean, method = methods, m = 5)


incompatible <- train_clean[, colnames(train_clean) != "sii"]
incompatible <- train_clean %>% select(-sii)
incompatible <- train_clean[, !(names(train_clean) %in% "sii")]


mice_compatible <- train_clean[, c("sii")]
incompatible <- train_clean[, -which(colnames(train_clean) == "sii")]


imputed_data <- mice(mice_compatible, method = "polyreg", m = 1)
completed_data <- complete(imputed_data)

final_data <- cbind(completed_data, incompatible)
# ---- #



