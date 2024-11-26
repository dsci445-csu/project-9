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



# Function to calculate the mode
Mode <- function(x) {
  uniq_x <- unique(x)
  uniq_x[which.max(tabulate(match(x, uniq_x)))]
}

# Ensure 'sii' is a factor variable for classification
train_clean$sii <- as.factor(train_clean$sii)

# Separate categorical and quantitative columns, keeping 'sii' in both sets
categorical_columns <- train_clean[, sapply(train_clean, is.factor) | sapply(train_clean, is.character)]
quantitative_columns <- train_clean[, sapply(train_clean, is.numeric)]

# Ensure 'sii' is included in both categorical and quantitative datasets
categorical_columns$sii <- train_clean$sii
quantitative_columns$sii <- train_clean$sii

# Remove PCIAT_PCIAT_Total from categorical and add it to quantitative
categorical_columns <- categorical_columns[, !names(categorical_columns) %in% "PCIAT_PCIAT_Total"]
quantitative_columns$PCIAT_PCIAT_Total <- train_clean$PCIAT_PCIAT_Total

# Convert columns with 'PCIAT' in their names to categorical variables, excluding 'PCIAT_PCIAT_Total'
pciat_columns <- grep("PCIAT", names(train_clean), value = TRUE)

# Remove 'PCIAT_PCIAT_Total' from the list of PCIAT columns
pciat_columns <- pciat_columns[!pciat_columns %in% "PCIAT_PCIAT_Total"]

# Convert identified PCIAT columns to factors (categorical variables)
train_clean[pciat_columns] <- lapply(train_clean[pciat_columns], factor)

# Impute NAs in categorical predictors with the mode of each column
impute_mode <- function(x) {
  if (is.factor(x) || is.character(x)) {
    return(factor(ifelse(is.na(x), Mode(x), as.character(x))))  # Replace NAs with mode
  } else {
    return(x)  # For non-categorical columns, leave them as is
  }
}

# Apply the imputation function to categorical predictors
categorical_predictors_imputed <- as.data.frame(lapply(categorical_columns, impute_mode))

# Check if the number of rows match between the predictors and 'sii'
if (nrow(categorical_predictors_imputed) == length(train_clean$sii)) {
  
  # Bind 'sii' to the imputed categorical predictors
  data_for_svm <- cbind(categorical_predictors_imputed, sii = train_clean$sii)
  
  # Train the SVM model
  svm_model <- svm(sii ~ ., data = data_for_svm, kernel = "radial")
  
  # Make predictions
  svm_predictions <- predict(svm_model, categorical_predictors_imputed)
  
  # Evaluate the model
  confusion_matrix <- table(Predicted = svm_predictions, Actual = train_clean$sii)
  
  # Print the confusion matrix
  print(confusion_matrix)
  
  # Optionally, calculate accuracy
  accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
  cat("Accuracy:", accuracy, "\n")
  
} else {
  cat("Error: The number of rows in the predictors and 'sii' do not match.\n")
}
