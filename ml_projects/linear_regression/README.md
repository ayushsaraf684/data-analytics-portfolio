# Lending Club Interest Rate Prediction using Linear Regression

## About the Project

I had already worked on the Lending Club dataset before, but that project was more focused on **data analysis and credit risk insights**.

While learning **Linear Regression**, I thought why not take the same dataset and try to take the project a little further from the machine learning side.

So this project focuses on using borrower and loan related information to **predict the interest rate of a Lending Club loan** using Linear Regression.

The interesting part of the project was not just building the model. I also wanted to understand how well the model was actually performing, whether there was any leakage in the features, how stable the results were, and whether regularisation could improve the model.

---

## Project Flow

The project is currently kept fairly simple in terms of files. Everything is handled inside one notebook.

```text
Lending Club Dataset
        ↓
Data Loading & Initial Exploration
        ↓
Feature Engineering
        ↓
Handling Missing Values
        ↓
Categorical Encoding
        ↓
Feature Selection / Removing Irrelevant Columns
        ↓
Log Transformations
        ↓
Train-Test Split
        ↓
Initial Linear Regression Model
        ↓
Model Evaluation
        ↓
Leakage Investigation
        ↓
Remove Leaky Feature
        ↓
Rebuild Linear Regression Model
        ↓
Residual Analysis
        ↓
Monte Carlo Validation
        ↓
5-Fold Cross Validation
        ↓
Ridge & Lasso Regression
        ↓
Final Model Comparison
```

---

## Files

There are only two files in this repository:

| File                             | Description                                                                                                       |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `credit_risk_LinReg_model.ipynb` | Main notebook containing the complete analysis, preprocessing, feature engineering, model building and evaluation |
| `lending_club_dataset.csv`       | Lending Club credit risk dataset used for the project                                                             |

I have kept everything inside one notebook instead of creating separate Python files for preprocessing, modelling and evaluation.

---

## Dataset

The project uses a Lending Club loan dataset containing borrower, credit history and loan related information.

The target variable for this project is:

```text
interest_rate
```

Some of the information used includes:

* Loan amount and term
* Employment length
* Debt-to-income related variables
* Credit utilisation
* Delinquency history
* Credit inquiries
* Credit account information
* Income verification
* Loan purpose
* Homeownership
* Application type

---

## Feature Engineering

A few features were created before modelling to make the existing variables more useful.

Some of the main ones were:

### Effective Income

For joint applications, joint income was used where available, otherwise individual income was used.

```text
effective_income
```

### Effective DTI

Similarly, joint DTI was used where available.

```text
effective_dti
```

### Credit Utilisation Ratio

```text
cr_util_ratio = total_credit_utilized / total_credit_limit
```

### Loan-to-Income Ratio

```text
loan_to_income = loan_amount / effective_income
```

### Credit History / Delinquency Flags

Flags were created for things such as:

* Recent credit inquiry
* Ever being 90 days late
* Ever being delinquent
* Missing employment length

For some credit history variables, missing values were treated as meaningful rather than simply deleting the rows.

---

## Preprocessing

Before training the model, several columns were removed.

This included:

* High-cardinality fields such as `emp_title` and `state`
* Post-origination variables such as `balance`, `paid_total`, `paid_principal`, and `loan_status`
* `grade` and `sub_grade`, since these are directly tied to the interest-rate outcome
* Duplicate income and DTI fields after creating their effective versions
* Metadata and other columns that were not useful for prediction

Categorical variables were then one-hot encoded.

Some heavily right-skewed financial variables were also log transformed:

```text
effective_income
loan_amount
total_credit_limit
```

---

## The First Model

The first Linear Regression model was trained using an **80/20 train-test split**.

The initial test results were:

| Metric |  Score |
| ------ | -----: |
| R²     | 0.6579 |
| RMSE   | 3.0115 |
| MAE    | 2.3406 |

At first, this looked reasonably good.

But the coefficient chart immediately showed something that did not make sense.

---

## Finding Feature Leakage

One feature stood out completely:

```text
installment_to_income
```

Its coefficient was around:

```text
235.93
```

while almost every other feature had much smaller coefficients.

After looking into how this feature was created, the reason became clear.

`installment_to_income` was calculated using the loan installment, and the installment itself is based on:

* Loan amount
* Loan term
* Interest rate

But **interest rate is the variable we are trying to predict**.

So the model was partly getting access to the answer through the installment feature.

This is a case of **feature leakage**.

The original R² of around 0.66 was therefore not a clean measure of the model's actual predictive ability.

---

## Rebuilding the Model

I removed:

```text
installment_to_income
```

and ran the modelling pipeline again.

The results changed quite a bit:

| Metric | Initial Model | Clean Model |
| ------ | ------------: | ----------: |
| R²     |        0.6579 |      0.4863 |
| RMSE   |        3.0115 |      3.6903 |
| MAE    |        2.3406 |      2.8594 |

The R² drop from **0.66 to 0.49** was actually useful because it confirmed that the previous model was getting a significant amount of its performance from the leaked feature.

The clean model gives a much more realistic picture of what Linear Regression can do using the remaining features.

---

## Model Stability

I did not want to rely only on one train-test split, so I tested the model across many different splits.

### Monte Carlo Validation

The model was trained and tested **1000 times** with different random states.

Results:

```text
Mean R²: 0.4612
Standard Deviation: 0.0174
```

The scores stayed within a fairly narrow range, so the model was not heavily dependent on one particular train-test split.

### 5-Fold Cross Validation

I also used 5-fold cross validation.

```text
R² Scores:
0.4781
0.4262
0.4396
0.4874
0.4789

Mean R²: 0.4620
Standard Deviation: 0.0244
```

Both validation approaches ended up around **0.46 R²**, which gives a more realistic idea of the model's general performance.

---

## Residual Analysis

I also checked the residuals instead of looking only at R², RMSE and MAE.

The residual plot showed a downward pattern.

Basically:

* At lower predicted interest rates, the model tends to underpredict.
* At higher predicted interest rates, the model tends to overpredict.

So the predictions are being pulled towards the middle.

This suggests that Linear Regression is missing some **non-linear relationships** in the data.

The same pattern was still present after removing the leaky feature, which makes it more likely that this is a limitation of the linear model rather than something caused by the leakage.

---

## Feature Coefficients

After removing the leaky feature, the coefficient chart became much more readable.

Some of the strongest positive coefficients were:

| Feature                               | Coefficient |
| ------------------------------------- | ----------: |
| `cr_util_ratio`                       |       +2.59 |
| `has_ever_been_delinquent`            |       +1.86 |
| `income_verification_status_Verified` |       +1.31 |
| `has_recent_inquiry`                  |       +1.09 |

Some of the strongest negative coefficients were:

| Feature                         | Coefficient |
| ------------------------------- | ----------: |
| `log_loan_amount`               |       -4.31 |
| `loan_purpose_renewable_energy` |       -2.48 |
| `loan_purpose_credit_card`      |       -0.80 |
| `loan_purpose_house`            |       -0.71 |
| `log_total_credit_limit`        |       -0.52 |

This was also one of the useful parts of the project because the coefficients made it possible to actually look at **which variables were associated with higher or lower predicted interest rates**.

For example, credit utilisation and delinquency related variables had positive coefficients, while log loan amount had a strong negative coefficient in this dataset.

These are model associations, not causal relationships.

---

## Ridge and Lasso

I also wanted to see whether regularisation could improve the model.

I tested:

* Linear Regression
* Ridge Regression
* Lasso Regression

The final comparison was:

| Model                   |   R² | RMSE |  MAE |
| ----------------------- | ---: | ---: | ---: |
| Basic Linear Regression | 0.49 | 3.69 | 2.86 |
| Ridge                   | 0.47 | 3.70 | 2.83 |
| Lasso                   | 0.47 | 3.72 | 2.85 |

For this dataset, regularisation did not improve the R².

Lasso did have another interesting result though. It reduced **17 out of 56 features to zero**, effectively removing them from the model.

So even though it did not improve predictive performance, it was still useful for understanding feature contribution.

---

## What I Learned

The biggest takeaway from this project was probably not the final R².

It was understanding that a model can give a good-looking score for the wrong reason.

The first model had an R² of around 0.66, but checking the coefficients led me to a feature that was indirectly containing the target variable itself.

Removing that feature brought the score down to around 0.49, but that result is much more meaningful.

I also got to work through:

* Feature engineering
* Missing value handling
* One-hot encoding
* Log transformations
* Train-test splitting
* Linear Regression
* Model evaluation
* Feature leakage
* Residual analysis
* Monte Carlo validation
* Cross validation
* Ridge Regression
* Lasso Regression

---

## Next Step

The residual analysis suggests that the relationship between borrower characteristics and interest rate is not completely linear.

So the natural next step would be to try a tree-based model such as:

```text
Random Forest
XGBoost
```

The main reason would be to see whether a non-linear model can capture relationships and feature interactions that Linear Regression is missing.

That would be the next stage of this project rather than something already tested here.
