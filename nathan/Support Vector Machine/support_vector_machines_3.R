library(readr)
library(dplyr)
library(e1071)
library(caret)
library(ggplot2)
library(tidymodels)


test = read_csv("test.csv")
train = read_csv("train.csv")

# Data Manipulation:
colnames(train) = gsub("-", "_", colnames(train))
colnames(test) = gsub("-", "_", colnames(test))

train_clean = train
test_clean = test

train_clean$sii = factor(train_clean$sii)
train_clean$sii = factor(train_clean$sii, levels = c(levels(train_clean$sii), "Missing"))
train_clean$sii[is.na(train_clean$sii)] = "Missing"

# Convert PCIAT columns to factors
pciat_columns = grep("PCIAT", names(train_clean), value = TRUE)
pciat_columns = pciat_columns[pciat_columns != "PCIAT_PCIAT_Total"]
train_clean[pciat_columns] = lapply(train_clean[pciat_columns], factor)

# Impute missing values for categorical columns
categorical_vars = train_clean %>%
  select(where(is.factor) | where(is.character)) %>%
  mutate(across(everything(), ~ replace(., is.na(.), "Missing")))

# Impute missing values for quantitative columns with median
quantitative_vars = train_clean %>%
  select(where(is.numeric)) %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

train_data = bind_cols(categorical_vars, quantitative_vars)

# Resize train to have the same columns as test
#test_clean[pciat_columns] = lapply(test_clean[pciat_columns], factor)
categorical_vars_test = test_clean %>%
  select(where(is.factor) | where(is.character)) %>%
  mutate(across(everything(), ~ replace(., is.na(.), "Missing")))
quantitative_vars_test = test_clean %>%
  select(where(is.numeric)) %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

test_data = bind_cols(categorical_vars_test, quantitative_vars_test)

# Ensure train and test have identical columns
train_data = train_data[, colnames(train_data) %in% colnames(test_data)]
test_data = test_data[, colnames(test_data) %in% colnames(train_data)]

# Add 'sii' column to test_data for prediction
test_data$sii = NA
train_data$sii = train_clean$sii

# SVM Model
#svm_fit = svm(sii ~ ., data = train_data, kernel = "radial", scale = FALSE)


svm_spec <- svm_rbf() %>% 
  set_engine("kernlab") %>% 
  set_mode("classification")

svm_fit_tidy <- workflow() %>%
  add_recipe(recipe(sii ~ ., data = train_data)) %>%
  add_model(svm_spec) %>%
  fit(data = train_data)

predictions = predict(svm_fit_tidy, new_data = test_data)

# Write predictions to CSV
output = data.frame(id = test$id, sii = predictions)
output = output %>% rename(sii = .pred_class)
output = output %>% mutate(sii = na_if(sii, "Missing"))
write_csv(output, "submission.csv")





pca = prcomp(train_data %>% select(where(is.numeric)), scale. = TRUE)
train_pca = data.frame(pca$x[, 1:2])  # Use first two principal components
train_pca$sii = train_data$sii  # Add `sii` (response)

train_pca = train_pca[train_pca$PC1 < 20, ]  # Filtering to keep only PC1 < 20

svm_model_pca = svm(sii ~ PC1 + PC2, data = train_pca, kernel = "radial", type = "C-classification")

x_range = seq(min(train_pca$PC1) - 1, max(train_pca$PC1) + 1, length.out = 500)
y_range = seq(min(train_pca$PC2) - 1, max(train_pca$PC2) + 1, length.out = 500)
grid = expand.grid(PC1 = x_range, PC2 = y_range)

grid$pred = predict(svm_model_pca, grid)

plot1 = ggplot() +
  geom_tile(data = grid, aes(x = PC1, y = PC2, fill = pred), alpha = 0.3) +  # Decision boundary
  geom_point(data = train_pca, aes(x = PC1, y = PC2, color = sii), size = 2) +  # Data points
  labs(title = "SVM Decision Boundaries",
       x = "Principal Component 1",
       y = "Principal Component 2") +
  scale_fill_manual(values = c("red", "blue", "green", "purple", "orange")) +  # Customize colors
  scale_color_manual(values = c("red", "blue", "green", "purple", "orange")) +
  theme_minimal()

print(plot1)

ggsave("svm_plot.png", plot = plot1, width = 10, height = 8, dpi = 300)
