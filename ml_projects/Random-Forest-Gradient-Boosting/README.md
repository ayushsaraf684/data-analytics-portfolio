
# Credit Risk Prediction using Ensemble Models (Random Forest + Gradient Boosting)

So this is another credit risk project, yeah I know I already have a couple more in this repo, this one is basically me trying to go one level up from single decision trees into ensemble stuff, Random Forest and Gradient Boosting, and comparing all three side by side to actually see what changes and why.

## What is this dataset about

Using the Give Me Some Credit dataset[https://www.openml.org/search?type=data&status=active&id=45577], its a classic one, the goal is to predict if a borrower is gonna hit serious delinquency, meaning 90+ days past due, within 2 years. Just wanna clear one thing here, this is NOT the same as predicting default, people mix these two up a lot, delinquency just means seriously late on payment, default is a different (bigger) thing, so keeping that distinction clear from the start.

## What I did with the data first

Data was messy in the usual ways, renamed all columns to snake_case first cause I can't work with those long camelCase names, then went into cleaning, revolving_util had some crazy outlier values so capped it at 1.5, debt_ratio capped at 99th percentile, age had a 0 in it somewhere which makes no sense so replaced with median and then capped overall at 87, and the three late payment columns (30-59, 60-89, 90) had these sentinel values like 96, 98 which are not real late counts, they're just codes, so capped those at 10 too. missing values in monthly_income and dependents got imputed.

## Feature engineering

Made a few new columns, total_times_late which just adds up all the late payment columns into one, this one turned out to be genuinely useful later (spoiler: its one of the top features in both models). also made income_per_dependent, had to be careful with the denominator here cause dependents can be 0, so only substituting 1 in that case so we're not dividing by zero. also made ever_late as a simple yes/no flag.

did log transforms too, debt_ratio_log and monthly_income_log, but only for visualization, not using these in the actual models, since log is a monotonic transform and doesnt change how a tree decides where to split, trees don't care about scale like that.

## EDA

did the usual stuff, checked target imbalance (its like 93-7 split, majority is NOT delinquent), KDE plots split by target, boxplot for income_per_dependent, correlation heatmap. wrote comments explaining what each plot is telling me, not just dumping plots for the sake of it.

## Models

Train test split was 80/20, stratified on target so both sets keep the same imbalance ratio.

Built 3 models:

1. Decision Tree - tuned using GridSearchCV, only 36 combos so exhaustive search made sense here, its cheap
2. Random Forest - tuned using RandomizedSearchCV instead, search space bigger and each fit trains way more trees so exhaustive wasn't worth it, did 15 iterations
3. Gradient Boosting - same reasoning, RandomizedSearchCV, 10 iterations

Made an evaluate_model() function that just prints accuracy, precision, recall, f1, roc-auc, shows confusion matrix, and stores everything in a results list so I could build a comparison table at the end without repeating code every time.

## The accuracy trap (important part, dont skip this)

Since target is like 93-7 imbalanced, a model that just says "not delinquent" for literally everyone gets 93% accuracy while catching zero actual delinquent people. So accuracy alone means basically nothing here, what actually matters is recall on the minority class, cause in lending, missing an actual risky borrower (false negative) costs way more than flagging a safe person for extra review (false positive).

## One thing that tripped me up and taught me something

I used class_weight='balanced' on Decision Tree and Random Forest to handle the imbalance. But turns out sklearn's GradientBoostingClassifier doesnt even have a class_weight parameter, so GB got trained with zero correction for the imbalance. Thats literally the reason GB shows 94% accuracy but only ~20% recall, its not that GB is a worse algorithm, its that it was never told the minority class matters more. Learned this only after noticing the recall number looked weirdly off compared to the other two.

interesting part is all 3 models are within like 0.015 ROC-AUC of each other, meaning they all learned pretty much the same underlying signal, the big difference in recall/precision numbers is mostly a class-weighting and threshold thing, not really an "algorithm understood data better" thing.

## Results

| model | accuracy | precision | recall | f1 | roc_auc |
|---|---|---|---|---|---|
| Decision Tree | 0.78 | 0.20 | 0.78 | 0.32 | 0.85 |
| Decision Tree (tuned) | 0.78 | 0.20 | 0.78 | 0.32 | 0.85 |
| Random Forest (tuned) | 0.81 | 0.23 | 0.76 | 0.35 | 0.86 |
| Random Forest | 0.83 | 0.24 | 0.72 | 0.36 | 0.86 |
| Gradient Boosting (tuned) | 0.94 | 0.57 | 0.20 | 0.29 | 0.86 |

going purely by recall (which is what actually matters for this problem), Decision Tree wins, but a single tree is unstable, small changes in data and the splits can shift a lot, so not something I'd trust for production honestly.

Random Forest is my pick overall, best balance of precision and recall, ties with GB on AUC, more stable than a lone tree.

Gradient Boosting looks the best if you only look at accuracy but thats misleading here for reasons explained above.

## Feature importance

checked feature importance for both RF and GB, both agree that revolving_util, total_times_late and the late payment columns are the strongest predictors, which honestly lines up with how credit risk works in real life anyway.

one thing to note, RF and GB dont fully agree with each other, ever_late ranks pretty high in RF but almost bottom in GB, reason is total_times_late and ever_late are kinda redundant with each other, boosting grabs total_times_late early and has nothing left for ever_late later, RF spreads credit around more since it only looks at a random subset of features at each split. not a bug, just how these two ensemble methods work differently.

also gini importance (the default one) is known to be a bit biased towards continuous features over binary ones, so not treating these numbers as 100% gospel, permutation importance would be a fairer way to check this, didnt implement it here but know what it does and why itd help, keeping it as a next step.

## What I'd do next if I had more time

- run permutation importance properly instead of just gini importance  
- actually tune the classification threshold instead of using default 0.5, especially since class weighting changes what the "right" threshold even is
- think about actual cost numbers, like what does one missed delinquent borrower cost vs one false alarm, and optimize around that instead of treating both errors equally

## Data source

Give Me Some Credit dataset, from OpenML / Kaggle, standard public dataset[https://www.openml.org/search?type=data&status=active&id=45577], linking source in the notebook itself.
