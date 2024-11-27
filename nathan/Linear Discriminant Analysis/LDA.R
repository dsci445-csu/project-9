library(recipes)
  library(readr)       
    library(dplyr)       
      library(caret)       
        library(ggplot2)
          library(parsnip)
            library(purrr)
              library(discrim)
                library(yardstick)
                  library(lda)
                    library(VIM)
                      library(MASS)

train = read_csv("train.csv")

# ---------------------------------------------------------------------------------------------------------------------- #
# Data Manipulation:
colnames(train) = gsub("-", "_", colnames(train)) # Replacing hyphens because R can't handle those
train_clean = train[, !grepl("Season", names(train))]
train_clean$sii = factor(train_clean$sii) # Making sure `sii` is a factor with 4 levels (plus extra level for NAs later)


train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing")) # Replacing NAs with new level
train_clean$sii[is.na(train_clean$sii)] = "Missing"

categorical_vars = train_clean[, sapply(train_clean, function(x) is.factor(x) | is.character(x))]
# Select categorical variables including 'sii'
# Identify columns that contain 'PCIAT' in their names but excluding 'PCIAT_PCIAT_Total' (quant. variable)
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns])

categorical_vars = categorical_vars %>%
  mutate(across(everything(), ~ replace(., is.na(.), "Missing")))

quantitative_vars = train_clean[, sapply(train_clean, is.numeric)]

quantitative_vars_imputed = quantitative_vars %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

train_data = bind_cols(categorical_vars, quantitative_vars_imputed)

quantitative_vars_imputed = quantitative_vars %>% mutate(sii = train_data$sii)

# ---------------------------------------------------------------------------------------------------------------------- #
# Linear Discriminant Analysis

lda_data_train = train_data
lda_data_train$sii = as.factor(lda_data_train$sii)  # Ensure `sii` is a factor for LDA

lda_data_train = subset(lda_data_train, select = -id)

# Perform Linear Discriminant Analysis
lda_model_train = lda(sii ~ ., data = lda_data_train)

# View the LDA model output
print(lda_model)

# Predicting using the LDA model
lda_predictions = predict(lda_model_train, lda_data_train)

# Add predictions to the original data
lda_data_train$predicted_sii = lda_predictions$class

# Confusion matrix to evaluate classification accuracy
confusion_matrix = table(lda_data_train$sii, lda_data_train$predicted_sii)

print("Confusion Matrix:")
print(confusion_matrix)

# Calculate accuracy
accuracy = sum(diag(confusion_matrix)) / sum(confusion_matrix)
print(paste("Accuracy:", round(accuracy * 100, 2), "%"))

# ---------------------------------------------------------------------------------------------------------------------- #
# Testing
# Read the test dataset
test = read_csv("test.csv")

# Replace hyphens in column names
colnames(test) = gsub("-", "_", colnames(test))

# Add 'sii' from train dataset based on 'id'
train_sii = subset(train_clean, select = c(id, sii))
test_clean = test %>% left_join(train_sii, by = "id", suffix = c("", "_train"))

# Ensure the 'sii' column is consistent with levels from train_clean
test_clean$sii = factor(test_clean$sii, levels = levels(train_clean$sii))
test_clean = test_clean[, !grepl("Season", names(test_clean))]

# Separate categorical and quantitative variables
# Select categorical variables (factor or character)
categorical_vars_test = test_clean[, sapply(test_clean, function(x) is.factor(x) | is.character(x))]

# Select quantitative variables (numeric)
quantitative_vars_test = test_clean[, sapply(test_clean, is.numeric)]


# Combine quantitative and categorical variables before imputation
test_combined = bind_cols(categorical_vars_test, quantitative_vars_test)

# Perform kNN imputation (with k = 3)
test_combined_imputed = kNN(test_combined, k = 3)

# Add random noise to numeric columns to maintain variability
test_combined_imputed = test_combined_imputed %>%
  mutate(across(where(is.numeric), ~ . + rnorm(length(.), mean = 0, sd = 0.01)))  # Add small noise

# Split back into quantitative variables (numeric) after imputation
quantitative_vars_test_imputed = test_combined_imputed[, sapply(test_combined_imputed, is.numeric)]
# Split back into categorical variables (factor or character) after imputation
categorical_vars_test_imputed = test_combined_imputed[, sapply(test_combined_imputed, function(x) is.character(x) | is.factor(x))]


# Re-combine the imputed data
# This is necessary because impuation method add logical variables into dataset
test_data = bind_cols(categorical_vars_test_imputed, quantitative_vars_test_imputed)

# Ensure 'sii' is part of the dataset
test_data$sii = test_clean$sii  # Add 'sii' to the dataset (raw column)

# Prepare data for LDA (ensure 'sii' is a factor)
lda_data_test = test_data
lda_data_test$sii = as.factor(lda_data_test$sii)

# Remove 'id' column or any non-predictor columns, if necessary
lda_data_test = subset(lda_data_test, select = -id)


# Perform Linear Discriminant Analysis
lda_model_test = lda(sii ~ ., data = lda_data_test)

print(lda_model_test)

lda_predictions = predict(lda_model_test, lda_data_test)

# Add predictions to the original data
lda_data_test$predicted_sii = lda_predictions$class

# Confusion matrix:
confusion_matrix = table(lda_data_test$sii, lda_data_test$predicted_sii)

print("Confusion Matrix:")
print(confusion_matrix)

# Calculate accuracy
accuracy = sum(diag(confusion_matrix)) / sum(confusion_matrix)
print(paste("Accuracy:", round(accuracy * 100, 2), "%"))

# PROBLEM: 100% accuracy?
# ---------------------------------------------------------------------------------------------------------------------- #

# For the train dataset (numerical variables only)
train_variances = apply(train_clean[, sapply(train_clean, is.numeric)], 2, var)

# For the test dataset (numerical variables only)
test_variances = apply(test_clean[, sapply(test_clean, is.numeric)], 2, var)

# View the variances
print("Train Dataset Variances:")
print(train_variances)

print("Test Dataset Variances:")
print(test_variances)
# ---------------------------------------------------------------------------------------------------------------------- #

# For the raw train dataset (numeric variables only)
train_variances_raw = apply(train[, sapply(train, is.numeric)], 2, var)

# For the raw test dataset (numeric variables only)
test_variances_raw = apply(test[, sapply(test, is.numeric)], 2, var)

# View the variances for the raw datasets
print("Raw Train Dataset Variances (Numeric Variables Only):")
print(train_variances_raw)

print("Raw Test Dataset Variances (Numeric Variables Only):")
print(test_variances_raw)


