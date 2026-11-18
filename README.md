# DSCI 445 - Predicting Vehicle Prices Using Statistical Learning Methods

## Project Overview

For our DSCI 445 Statistical Machine Learning project at Colorado State University, we are using vehicle specifications and performance characteristics to predict vehicle prices.

Our main goal is to compare several statistical learning methods covered throughout the semester and determine which model provides the most accurate predictions. We also want to see which vehicle characteristics have the strongest relationship with price.

## Group Members

- **Harrison Eaton**
- **Joey Huggins**
- **Halle Hablutzel**
- **Abdul Alenazi**

## Research Question

Which statistical learning method provides the most accurate predictions of vehicle prices using vehicle specifications and performance characteristics?

## Dataset

Our selected dataset contains **1,218 observations and 11 variables**, with very little missing data.

**Response Variable:** Cars Prices

**Predictor Variables:**
- Company Names
- Cars Names
- Engines
- CC/Battery Capacity
- HorsePower
- Total Speed
- Performance (0-100 km/h)
- Fuel Types
- Seats
- Torque

We chose this dataset because it contains both numerical and categorical variables, requires relatively little cleaning, and gives us a good opportunity to apply the methods we have learned in class.

We expect characteristics such as horsepower, engine size, torque, vehicle performance, and manufacturer to have strong relationships with price.

## Statistical Learning Methods

We plan to compare eight statistical learning methods.

### Traditional Regression
- Linear Regression

### Model Selection
- Best Subset Selection
- Forward Stepwise Selection
- Backward Stepwise Selection

### Regularization
- Ridge Regression
- Lasso Regression

### Dimension Reduction
- Principal Components Regression (PCR)
- Partial Least Squares (PLS)

Each model will use the same training and testing split so our results can be compared fairly.

## Model Evaluation

We will use **10-fold cross-validation** on the training data to select and tune our models.

Once each model has been trained, we will evaluate its performance using **Test Mean Squared Error (MSE)**.

Our goal is to compare test MSE across all eight models and determine which method performs best on our dataset. We will also examine which predictors appear to be most important and discuss any differences between the methods.

## Repository Structure

The repository is organized into separate folders so that everyone in the group can work on different parts of the project.

### `models/`

Contains the R scripts for our eight statistical learning models.

| File | Purpose |
|---|---|
| `linear_regression.R` | Multiple linear regression |
| `best_subset.R` | Best subset selection |
| `forward_stepwise.R` | Forward stepwise selection |
| `backward_stepwise.R` | Backward stepwise selection |
| `ridge.R` | Ridge regression |
| `lasso.R` | Lasso regression |
| `pcr.R` | Principal components regression |
| `pls.R` | Partial least squares |

### `scripts/`

Contains the scripts used to prepare the dataset before training our models.

- `data_cleaning.R` - Data cleaning and preprocessing
- `data_split.R` - Creating our training and testing datasets

### `evaluation/`

Contains code for evaluating model performance.

- `10F_CV.py` - Planned 10-fold cross-validation and model comparison

We will use our evaluation results to compare the models and determine which one has the lowest test MSE.

### `final_unclean_data/`

Contains our selected vehicle dataset and its cleaning script.

- `unclean_cars.csv` - Original dataset before preprocessing
- `clean_the_data.py` - Python script for cleaning and preparing the dataset

### `dont_use_this_data/`

Contains datasets we considered earlier in the project but are not currently planning to use.

These files are kept for reference.

### `second_data/`

Contains additional data exploration work from another dataset we considered.

### `paper/`

Will contain our final project paper written in R Markdown, including our motivation, methodology, results, and conclusions.

### `presentation/` and `slides/`

Reserved for our final presentation and reproducible R Markdown slides.

## Project Workflow

We plan to complete the project in five main steps.

1. **Data Cleaning and Preprocessing:** Prepare the dataset, handle missing values, and make sure all variables are ready for modeling.
2. **Exploratory Data Analysis (EDA):** Explore relationships between vehicle characteristics and prices through summary statistics and visualizations.
3. **Model Building:** Implement and train each of our eight statistical learning methods.
4. **Cross-Validation and Model Comparison:** Tune our models using 10-fold cross-validation and compare their final test MSE.
5. **Final Paper and Presentation:** Summarize our methodology, findings, and conclusions in a reproducible paper and presentation.

## Project Timeline

| Date | Milestone |
|---|---|
| October 27, 2026 | Groups formed and proposal meeting scheduling |
| November 10, 2026 | Project proposal meeting deadline |
| December 4, 2026 | First draft of paper due |
| December 8, 2026 | In-class presentations |
| December 10, 2026 | In-class presentations |
| December 14, 2026 | Final paper and presentation due by 4:00 PM |

## Project Deliverables

Our final project should include:

- A **5-10 page paper** written in R Markdown with references.
- An **8-10 minute in-class presentation** with participation from all four group members.
- Reproducible presentation slides written in R Markdown.
- Our project code, datasets, and results maintained through GitHub.

We need to use GitHub throughout the project to track contributions and make sure our work can be reproduced.

## Project Status

This project is currently in development. Our group has selected a project topic, organized the repository, and started preparing our dataset and model implementations.

We will update the repository as we complete the data cleaning, exploratory analysis, statistical models, and final deliverables.

## Resources

- [DSCI 445 Course Website](https://dsci445-csu.github.io/)
- [DSCI 445 Project Requirements](https://dsci445-csu.github.io/project/)
- [Colorado State University](https://www.colostate.edu/)
- [Used Car Price Prediction Challenge](https://www.kaggle.com/competitions/used-car-price-prediction-challenge/data?utm_source=chatgpt.com)
