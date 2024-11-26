library(e1071)
library(dplyr)
library(missForest)
library(readr)
library(caret)
library(tidyr)

test = read_csv("test.csv")
train = read_csv("train.csv")
# data_dictionary = read_csv("data_dictionary.csv")

# Cleaning
train_clean = train %>% select(-ends_with("Season")) 
train_clean$sii = factor(train_clean$sii)

colnames(train_clean) = gsub("-", "_", colnames(train_clean))

train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing"))
train_clean$sii[is.na(train_clean$sii)] = "Missing"



categorical_vars = train_clean %>% select(where(is.factor) | where(is.character) | 'sii')

quantitative_vars = train_clean %>% select(where(is.numeric) | 'sii')


# Identify columns that contain 'PCIAT' in their names but exclude 'PCIAT_PCIAT_Total'
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
categorical_vars = cbind(categorical_vars, train_clean[, pciat_columns]) # Extract these columns and add them to the categorical variables


# PERFORM SVM on quantitative dataset:

# Impute missing values for quantitative variables (replace NA with the median)
train_quantitative_imputed = train_quantitative %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

# Check if there are any remaining NA values in the dataset
sum(is.na(train_quantitative_imputed))

# Split the data into predictors (X) and target variable (y)
X = train_quantitative_imputed %>% select(-sii)
y = train_quantitative_imputed$sii

# Train the SVM model with radial kernel
svm_model = svm(x = X, y = y, kernel = "radial", cost = 1, scale = TRUE)

# Print the model summary
summary(svm_model)

# Predict using the trained SVM model
predictions = predict(svm_model, X)

# Evaluate model performance (e.g., confusion matrix)
confusion_matrix = table(predictions, y)
print(confusion_matrix)





# PERFORM SVM on categorical dataset:


# Use the dummyVars function from caret for one-hot encoding of categorical variables
dummy_model = dummyVars(as.factor(sii) ~ ., data = categorical_vars, fullRank = TRUE)
X_dummies = predict(dummy_model, newdata = categorical_vars)

# Convert to a data frame
X_dummies = data.frame(X_dummies)

# Ensure the target variable 'sii' is a factor
train_clean$sii = as.factor(train_clean$sii)

# Bind the target variable 'sii' with the one-hot encoded predictor variables
train_with_sii = cbind(X_dummies, sii = train_clean$sii)

# Impute missing values in the one-hot encoded data if necessary (replace NA with the mode for categorical variables)
train_with_sii_imputed = train_with_sii %>%
  mutate(across(where(is.factor), ~ ifelse(is.na(.), names(sort(table(.), decreasing = TRUE))[1], .))) %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

# Check for any remaining NA values
sum(is.na(train_with_sii_imputed))

# Split the data into predictors (X) and target variable (y)
X = train_with_sii_imputed %>% select(-sii)
y = train_with_sii_imputed$sii

# Train the SVM model with radial kernel
svm_model = svm(x = X, y = y, kernel = "radial", cost = 0.5, scale = TRUE)

# Print the model summary
summary(svm_model)

# Predict using the trained SVM model
predictions = predict(svm_model, X)

# Evaluate model performance (e.g., confusion matrix)
confusion_matrix = table(predictions, y)
print(confusion_matrix)
