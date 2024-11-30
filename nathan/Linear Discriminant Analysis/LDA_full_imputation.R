library(recipes)
library(readr)       
library(dplyr)       
library(caret)       
library(ggplot2)
library(parsnip)
library(purrr)
library(discrim)
library(tidyr)
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
print(lda_model_train)

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
# LDA Visualization

# Check if the number of linear discriminants is sufficient
lda_discriminants = lda_predictions$x
lda_discriminants = as.data.frame(lda_discriminants)
#lda_discriminants = lda_discriminants %>% filter(LD1 < 38)

if (ncol(lda_discriminants) >= 2) {
  # Extract the first two linear discriminants
  lda_data_train$LD1 = lda_discriminants[, 1]  # First Linear Discriminant
  lda_data_train$LD2 = lda_discriminants[, 2]  # Second Linear Discriminant
  lda_data_train_new = lda_data_train %>% filter(LD1 < -8)
  # Plot the LDA results
  ggplot(lda_data_train_new, aes(x = LD2, y = LD1, color = sii)) +
    geom_point(alpha = 0.7) +
    labs(title = "LDA: Linear Discriminants 2 vs 1",
         x = "Linear Discriminant 2",
         y = "Linear Discriminant 1") +
    theme_minimal() +
    scale_color_manual(values = c("red", "blue", "green", "purple", "orange"))  # Adjust colors as needed
} else {
  print("Insufficient linear discriminants for visualization.")
}

# ---------------------------------------------------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------------------------------------------------- #
# Testing
# Read the test dataset
test = read_csv("test.csv")

colnames(test) = gsub("-", "_", colnames(test))

train_sii = subset(train_clean, select = c(id, sii))
test_clean = test %>% left_join(train_sii, by = "id", suffix = c("", "_train"))

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
test_data$sii = test_clean$sii  # Add 'sii' to the dataset (raw column)

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