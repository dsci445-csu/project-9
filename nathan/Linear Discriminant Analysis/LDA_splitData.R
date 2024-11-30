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
set.seed(445)
train = read_csv("train.csv")

train_clean = train[!is.na(train$sii), ]

colnames(train) = gsub("-", "_", colnames(train)) # Replacing hyphens because R can't handle those
train_clean = train_clean[, !grepl("Season", names(train))]
train_clean$sii = factor(train_clean$sii) # Making sure `sii` is a factor with 4 levels (plus extra level for NAs later)

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

# ---------------------------------------------------------------------------------------------------------------------- #
# Removing collinear variables:

# Compute correlation matrix for quantitative variables
correlation_matrix = cor(quantitative_vars_imputed)

# Find highly correlated pairs
high_corr_pairs = findCorrelation(correlation_matrix, cutoff = 0.8, verbose = TRUE)

# Remove highly correlated variables
quantitative_vars_filtered = quantitative_vars_imputed[, -high_corr_pairs]

train_data = bind_cols(categorical_vars, quantitative_vars_filtered)

quantitative_vars_filtered = quantitative_vars_filtered %>% mutate(sii = train_data$sii)

# ---------------------------------------------------------------------------------------------------------------------- #
# Split the data into training and test sets (80% train, 20% test)

set.seed(445)  # Ensure reproducibility
trainIndex <- createDataPartition(train_data$sii, p = 0.8, list = FALSE)
train_set <- train_data[trainIndex, ]
test_set <- train_data[-trainIndex, ]

# ---------------------------------------------------------------------------------------------------------------------- #
# Linear Discriminant Analysis (LDA)

lda_data_train = train_set
lda_data_train$sii = as.factor(lda_data_train$sii)  # Ensure `sii` is a factor for LDA

lda_data_train = subset(lda_data_train, select = -id)

# Perform Linear Discriminant Analysis
lda_model_train = lda(sii ~ ., data = lda_data_train)

# View the LDA model output
print(lda_model_train)

# Predicting using the LDA model
lda_predictions_train = predict(lda_model_train, lda_data_train)

# Add predictions to the original data
lda_data_train$predicted_sii = lda_predictions_train$class

# Confusion matrix to evaluate classification accuracy
confusion_matrix_train = table(lda_data_train$sii, lda_data_train$predicted_sii)

print("Train Confusion Matrix:")
print(confusion_matrix_train)

# Calculate accuracy
accuracy_train = sum(diag(confusion_matrix_train)) / sum(confusion_matrix_train)
print(paste("Train Accuracy:", round(accuracy_train * 100, 2), "%"))

error_rate_train = 1 - accuracy_train
print(paste("Train Error Rate:", round(error_rate_train * 100, 2), "%"))

# ---------------------------------------------------------------------------------------------------------------------- #
# Testing on the Test Set

lda_data_test = test_set
lda_data_test$sii = as.factor(lda_data_test$sii)

# Remove 'id' column or any non-predictor columns, if necessary
lda_data_test = subset(lda_data_test, select = -id)

# Perform Linear Discriminant Analysis on the test set
lda_model_test = lda(sii ~ ., data = lda_data_test)

# Predict using the LDA model on the test set
lda_predictions_test = predict(lda_model_test, lda_data_test)

# Add predictions to the original data
lda_data_test$predicted_sii = lda_predictions_test$class

# Confusion matrix for the test set
confusion_matrix_test = table(lda_data_test$sii, lda_data_test$predicted_sii)

print("Test Confusion Matrix:")
print(confusion_matrix_test)

# Calculate accuracy on the test set
accuracy_test = sum(diag(confusion_matrix_test)) / sum(confusion_matrix_test)
print(paste("Test Accuracy:", round(accuracy_test * 100, 2), "%"))

error_rate_test = 1 - accuracy_test
print(paste("Test Error Rate:", round(error_rate_test * 100, 2), "%"))
