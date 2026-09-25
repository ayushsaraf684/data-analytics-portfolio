# SBA Loan Default Prediction using XGBoost

This project focuses on applying XGBoost to a large, messy credit-risk dataset. Rather than comparing multiple algorithms, the focus here is on building and tuning an XGBoost model and understanding the techniques that make it effective and efficient on larger real-world data.

---
## The dataset

National SBA loan dataset, straight from the U.S. Small Business Administration, roughly 899,000 loans, 27 variables, spanning 1987 through 2014. Target is `MIS_Status`, whether the loan was paid in full or charged off/defaulted. Class split is around 87-13, so imbalanced but not as extreme as the delinquency problem in my other credit risk repo.

---

## Cleaning it up

This dataset came in genuinely dirty, way more than a typical Kaggle-polished one, which honestly made it a better exercise. A few things that needed fixing before any modeling could happen:

- money columns were stored as strings with dollar signs, had to strip those before converting to numeric
- `ApprovalFY` had a literal `1976A` value sitting in there, not a typo I introduced, that's just how it came in the raw file
- `RevLineCr` and `LowDoc` had a mix of real category values and garbage entries, mapped the garbage down to a neutral 0 rather than dropping those rows, since dropping would've meant losing a meaningful chunk of data
- `NewExist` had 0s where the coding should only ever be 1 or 2, treated those as missing and filled with the mode
- dropped rows with clearly broken values too, `Term = 0` doesn't make sense for a loan, and there were a handful of `NoEmp`, `CreateJob`, `RetainedJob` entries sitting way past any realistic range (like 9999), those got filtered out as data entry errors rather than real businesses

---

## Feature engineering

Didn't want to just throw raw columns at the model, so built a handful of derived features that actually map to how a lender would reason about risk:

- `HasFranchise`, binary flag off the franchise code column
- `SBA_Ratio` and `Disbursement_Ratio`, how much of the loan the SBA actually guaranteed vs. what was approved, and how much was disbursed vs. approved, both proxy for how much skin the lender itself has in the game
- `Processing_Days`, gap between approval and disbursement
- `Total_Jobs` and `Jobs_Per_Employee`, combining the job creation/retention columns into something more interpretable
- `Same_State`, whether the borrower and the lending bank are in the same state, then dropped the raw `State` column afterward since encoding 50+ states directly wasn't worth the time cost right now
- `Term_Bucket`, grouping loan term length into short/medium/long instead of leaving it as a raw number

One decision worth calling out specifically: the raw `NAICS` industry code came in as a messy 6-digit number, way too granular to use directly. First instinct was to just drop the whole column, but that felt wrong, industry sector is one of the more well known drivers of small business default risk in actual credit literature, so dropping it entirely would've meant throwing away real signal for convenience. Ended up keeping just the first 2 digits (the official NAICS sector code) and mapping those to their actual sector names using the U.S. Census Bureau's NAICS reference, then one-hot encoded that instead of the full code. Best of both, kept the industry signal, dropped the noise underneath it.

Also dropped `ChgOffPrinGr` (charge-off principal amount) entirely, that column is only ever nonzero *after* a loan has already defaulted, so leaving it in would've been straight up leaking the answer into the model.

--- 

## Why XGBoost specifically, and why the sklearn API

Wanted to go one level past the gradient boosting I'd already built elsewhere and actually understand what XGBoost is doing differently under the hood, the quantile-sketch based histogram splitting, the regularization terms, `scale_pos_weight` for imbalance, that kind of thing. Used the sklearn-style `XGBClassifier` rather than the native `xgb.train()` / `DMatrix` API, mainly for consistency with the rest of my pipeline (`train_test_split`, same fit/predict pattern as everything else), fully aware that under the hood it still converts to a `DMatrix` and runs the same histogram-based training either way. Not a knowledge gap, just a pipeline consistency choice.

Key params, and the reasoning behind the ones that actually matter:

- `tree_method='hist'`, splits get evaluated against pre-binned quantile buckets instead of scanning every single value, this is the actual optimization that makes XGBoost fast at this row count
- `scale_pos_weight`, set to the negative/positive class ratio, tells the model that missing an actual defaulter costs more than a false alarm, which lines up with how lending risk actually works
- `early_stopping_rounds=50` with `n_estimators=2000`, model stopped at iteration 1997, meaning it basically used its full budget rather than plateauing early. worth being upfront about that rather than pretending it converged cleanly, if I revisit this I'd bump `n_estimators` higher and drop the learning rate further to see if it keeps improving
- left `gamma`, `reg_alpha`, `reg_lambda` at their defaults on purpose rather than padding the model definition with parameters set to values that weren't actually doing anything different

---

## Results

| Metric | Score |
|---|---|
| Accuracy | 0.935 |
| Precision (default class) | 0.75 |
| Recall (default class) | 0.94 |
| F1 | 0.837 |
| ROC-AUC | 0.981 |
| PR-AUC | 0.920 |

Confusion matrix on the test set:

|  | Predicted: Paid | Predicted: Default |
|---|---|---|
| **Actual: Paid** | 135,072 | 9,503 |
| **Actual: Default** | 1,873 | 29,248 |

Recall sitting well above precision here isn't an accident, that's `scale_pos_weight` doing exactly what it was set up to do. Out of every loan that actually defaulted, the model catches 94% of them, at the cost of flagging some genuinely fine borrowers along the way (the 9,503 false positives). In a lending context that trade is the right one to make, a missed default is a real loss, a flagged-but-actually-fine loan just means extra manual review.

Leading with PR-AUC over ROC-AUC here too, ROC-AUC gets an easy boost from the sheer volume of true negatives when the classes are this imbalanced, PR-AUC is the harder, more honest number, and 0.92 against a ~13% base default rate is a genuinely strong result.

---

## Cross Validation

After the initial model evaluation, I wanted to check whether the model performance was stable instead of relying only on one train/test split.

I first tried using **RandomizedSearchCV** to combine cross-validation with hyperparameter tuning. The idea was to test different combinations of parameters and see whether a better-performing XGBoost setup could be found.

However, the search became very computationally expensive. The dataset is large, and each XGBoost model was being trained with a large number of estimators across multiple cross-validation folds. Even after reducing the number of combinations, the search was still taking too long for the relatively small improvement I was looking for.

So instead of continuing with a large hyperparameter search, I switched to **5-fold Stratified K-Fold cross-validation** using the existing model parameters.

This allowed me to check whether the model's ROC-AUC stayed consistent across different subsets of the training data, without having to train a large number of different parameter combinations.

The five ROC-AUC scores were:

- Fold 1 → **0.98068**
- Fold 2 → **0.98116**
- Fold 3 → **0.98036**
- Fold 4 → **0.98101**
- Fold 5 → **0.98064**

Mean ROC-AUC → **0.98077**  
Standard deviation → **0.00028**

The scores were very close to each other, so the model's ROC-AUC was quite stable across the five folds.

After this, I compared the **2,000-estimator and 3,000-estimator models**. The 3,000-estimator model gave a small improvement in the final test results, so I used it as the final model.

I also checked the feature importance from both models. The overall ranking was very similar, with `Term`, `Term_Bucket`, `ApprovalFY`, `UrbanRural_Unknown`, `Same_State`, and `SBA_Ratio` among the most important features.

Finally, I tested different classification thresholds to see the precision-recall trade-off instead of looking only at the default 0.5 threshold. The results showed that lowering the threshold increased recall but also created more false positives, while increasing it improved precision at the cost of recall. I kept the threshold analysis as part of the evaluation rather than choosing a new threshold only because it gave the highest F1 score.

---

## Where this stops, on purpose

This project stops here without going deeper into exhaustive hyperparameter tuning.

I did try `RandomizedSearchCV`, but the computational cost was high for the size of the dataset and the number of estimators being used. Instead, I used Stratified K-Fold to check model stability, compared the 2,000 and 3,000-estimator models, checked feature importance, and evaluated the final model using multiple classification metrics.

The final 3,000-estimator model gave:

- Accuracy → **0.9361**
- Precision → **0.7581**
- Recall → **0.9390**
- F1 → **0.8389**
- ROC-AUC → **0.9812**
- PR-AUC → **0.9211**

The goal of this project was mainly to understand XGBoost properly and build the complete modelling process around it. At this point, I think that part of the project is complete.

---

## What I'd explore with more time

### Out-of-time validation

The dataset covers loans from **1987 to 2014**, including the 2008 financial crisis. A random train/test split means loans from different periods can appear in both training and testing.

With more time, I would try holding out the most recent years as a separate test period and check how well the model performs on a later period that it did not see during training.

### Other feature importance methods

While reading about feature importance, I also came across **permutation importance**.

It looks like another way of checking which features are actually useful to the model, but I would need to study it properly before using it and comparing it with the built-in XGBoost importance.

### Native XGBoost API

Another thing I'd like to explore is the native `DMatrix` / `xgb.train()` API. I used the `XGBClassifier` interface here, but learning the native API would give me more hands-on understanding of how XGBoost works underneath the sklearn interface.

These are areas I would explore in a follow-up project rather than adding them here just for the sake of making this notebook longer.

---

## Data source

National SBA loan dataset, U.S. Small Business Administration, sourced as a public dataset covering 1987 to 2014, linked directly in the notebook. NAICS sector reference from the [U.S. Census Bureau](https://www.census.gov/naics/).

BTW you can click [here](https://pengdsci.github.io/datasets/) directly to get the datasets, download all of them and keep it in a folder. Open your Jupyter Notebook in the same folder to so that you can use my NoteBook directly
