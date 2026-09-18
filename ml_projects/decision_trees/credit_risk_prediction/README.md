# Credit Risk Prediction using Decision Tree

This is one of my first end-to-end machine learning projects. The goal was to predict
whether a loan applicant will repay their loan or default on it, using a Decision Tree
classifier built in Python.

I picked this dataset because it felt close to a real business problem. Banks do
exactly the same thing, they look at a borrower's income, credit history, and loan details
to decide whether to approve a loan or not. I wanted to see if a simple model
could learn those patterns from data.

---

## Dataset

**Source:** [Credit Risk Dataset -> Kaggle (laotse)](https://www.kaggle.com/datasets/laotse/credit-risk-dataset)

The dataset has 32,581 rows and 12 columns. Each row is one loan application.
The target column is `loan_status` -> 0 means the person repaid the loan, 1 means
they defaulted.

| Column | What it means |
|---|---|
| person_age | Age of the borrower |
| person_income | Annual income |
| person_home_ownership | RENT / OWN / MORTGAGE / OTHER |
| person_emp_length | Years of employment |
| loan_intent | Why they took the loan (education, medical, etc.) |
| loan_grade | Credit grade assigned ->> A (best) to F (worst) |
| loan_amnt | Loan amount |
| loan_int_rate | Interest rate on the loan |
| loan_percent_income | Loan amount as a percentage of income |
| cb_person_default_on_file | Has this person defaulted before? (Y/N) |
| cb_person_cred_hist_length | How many years of credit history they have |
| loan_status | **Target** -> 0 = repaid, 1 = defaulted |

---

## What I Did -> Step by Step

### 1. Data Cleaning

The dataset had two columns with missing values:
- `person_emp_length` -> 895 missing values
- `loan_int_rate` -> 3,116 missing values

I also found some rows with values that made no logical sense like a person with
age 132 or employment length of 123 years. I removed those first (7 rows total),
and then filled the remaining missing values with the **median** of each column.

I used median instead of mean because both columns had extreme outliers. The mean
gets pulled up by those extreme values, which would give an unrealistic fill value.
Median is more grounded in what the actual data looks like.

After cleaning: **31,679 rows remaining**.

### 2. Encoding

The model can only work with numbers, so I converted the text columns:

- `loan_grade` -> ordinal encoding (A=0, B=1, C=2, D=3, E=4, F=5) because there
  is a clear order here -> A is genuinely better than B
- `cb_person_default_on_file` -> binary encoding (Y=1, N=0)
- `person_home_ownership` and `loan_intent` -> one-hot encoding because there is
  no meaningful order between RENT and OWN, or between EDUCATION and MEDICAL

### 3. Feature Engineering

I created 4 new columns that don't exist in the raw data but capture something
more meaningful for predicting risk:

**Employment to Age Ratio**
```
person_emp_length / person_age
```
How much of their life have they been employed? A 25-year-old with 5 years of
employment is more stable than a 40-year-old with 5 years. Raw employment length
alone doesn't tell you this.

**Credit History Ratio**
```
cb_person_cred_hist_length / person_age
```
Did they start building credit early in life? Someone who has had credit since
they were young is generally more financially responsible.

**Interest Burden**
```
(loan_int_rate / 100) * loan_amnt
```
The actual interest amount they are paying on top of the loan. Captures real
financial stress better than just knowing the rate or the loan amount alone.

**Loan to Credit History Ratio**
```
loan_amnt / cb_person_cred_hist_length
```
Asking for a large loan with very little credit track record is a red flag. This
feature captures that. The minimum credit history length in this dataset is 2, so
no division by zero issue here.

---

## Model

I used a **Decision Tree Classifier** from scikit-learn.

```python
DecisionTreeClassifier(
    criterion='gini',
    max_depth=5,
    min_samples_split=20,
    min_samples_leaf=10,
    class_weight='balanced',
    random_state=42
)
```

A few decisions worth explaining:

- `class_weight='balanced'` -> the dataset has about 78% repaid and 22% defaulted.
  Without this, the model would mostly learn to predict "repaid" since that's the
  majority. Balanced weighting gives more importance to the minority class (defaulters).
- `max_depth=5` -> limits how deep the tree grows, which reduces overfitting.
- `min_samples_split=20` and `min_samples_leaf=10` -> the tree needs at least 20
  samples to make a split, and at least 10 samples in each leaf node. Prevents
  the tree from making splits on very small groups.

**Train-Test Split:** 80% training, 20% testing, with `stratify=y` to make sure
the proportion of defaults is the same in both sets.

---

## Results -> Before Pruning

| Metric | Value |
|---|---|
| Accuracy | 92% |
| ROC-AUC | 0.9006 |
| Precision (defaults) | 89% |
| Recall (defaults) | 72% |

The problem was clear in the numbers: **training accuracy was 100%, test was 92%**.
The model had memorised the training data rather than learning real patterns. This
is called overfitting.

---

## Pruning

To fix the overfitting, I used **cost complexity pruning**. The idea is to find
a value (called alpha) that penalises the tree for being too complex. Higher alpha
= simpler tree.

I tested every possible alpha value and used **5-fold cross validation** to find
the best one, meaning for each alpha, the data was split 5 different ways and
the average accuracy was measured. This is more reliable than just picking the
alpha that works best on one split.

**Best alpha found: 0.000274**

Both the simple method and cross validation agreed on the same value, which gave
me more confidence that it was the right choice.

---

## Results After Pruning

| Metric | Before Pruning | After Pruning |
|---|---|---|
| Train Accuracy | 100% | 93.5% |
| Test Accuracy | 92% | 93.7% |
| ROC-AUC | 0.9006 | 0.9179 |
| Precision (defaults) | 89% | 99% |
| Recall (defaults) | 72% | 72% |

A few things stand out here:

- **Test accuracy went up after pruning** -> from 92% to 93.7%. Removing the
  overfitting actually improved performance on unseen data.
- **Precision on defaults jumped from 89% to 99%** -> when the pruned model
  flags someone as a defaulter, it is correct 99% of the time. Only 14 repayers
  were incorrectly flagged across the entire test set.
- **Recall stayed at 72%** -> the model still misses about 1 in 4 actual
  defaulters. This is the main limitation.

### Confusion Matrix Breakdown (Pruned Model)

Out of 6,336 people in the test set:

- **4,957** repayers correctly identified (out of 4,971)
- **980** defaulters correctly caught (out of 1,365)
- **14** repayers incorrectly flagged as defaulters *(false positives)*
- **385** defaulters predicted as safe borrowers *(false negatives)*

The false negatives are the bigger concern in a real banking scenario -> these are
people who would default but the model approved them. Getting this number lower
would require either adjusting the threshold or trying a more complex model.

---

## Feature Importance

The top features the model relied on most were `loan_percent_income` and
`loan_grade`. This makes intuitive sense -> how much of your income the loan
takes up, and what grade the bank assigns you, are strong indicators of whether
you will struggle to repay.

The engineered features (`interest_burden`, `loan_to_cred_hist_ratio`) also
showed up as meaningful, which validated the decision to create them.

---

## Libraries Used

- `pandas` -> data loading and manipulation
- `numpy` -> for cross validation argmax calculation
- `matplotlib` and `seaborn` -> charts and visualisations
- `scikit-learn` -> Decision Tree, train-test split, cross validation, confusion matrix

---

## What I Learned

- Cleaning data before calculating medians matters. I removed the illogical outliers
  first and then calculated the median -> otherwise those extreme values would have
  skewed the fill values.
- Feature engineering is not just adding more columns. Each feature I added had
  a reason behind it. The ratio features captured relationships between columns
  that the model couldn't discover on its own.
- A perfect training accuracy (100%) is not a good sign. It usually means the
  model has memorised the data, not learned from it.
- Pruning made the model both simpler and better -> not a trade-off, just better.
- Cross validation and the simpler method both agreed on the same alpha. When two
  different approaches give the same answer, it is usually the right one.

---

## Limitations

- Recall on defaults is 72%. About 385 people in the test set were actually going
  to default but the model predicted they would repay. In a real bank, those are
  approved loans that would go bad.
- The dataset is synthetic (simulated), so real-world performance could differ.
- Next steps: try Logistic Regression or XGBoost on the same data and compare results.
