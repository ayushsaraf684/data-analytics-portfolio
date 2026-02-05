# Project Journey, Key Insights & Final Strategy

---

## My Journey — From Raw Data to Full Portfolio Understanding

To begin this project, I used **Pandas** to work with the raw loan data. My initial goal was to clean, validate and prepare the dataset for analysis. I created behaviour-based risk flags, combined the risk scores, and ensured the dataset was logically consistent.

When the data were prepared, I used **SQL** to conduct my analysis at portfolio level. I developed multiple queries in order to obtain a better understanding of the loan's health, borrower's behaviours, grade-based risk, utilization stress and stability indicators. I generated output tables that could be exported to Excel for easy reviewing and validating.

During the analysis, my initial intention was not to create as many sections as I did. Yet, as I continued to explore the data, I began discovering new patterns and questions. This curiosity led me to continue searching for anomalies in the dataset, resulting in my finding unexpected behaviours and behaviour-based risk signals, as well as odd grade to income combinations.

That is why this project was divided into multiple sections – each section was designed to answer a different level of the same question:
**“Where does risk actually come from in this portfolio?”**
"We

## Key Analysis Insights (Most Important Learnings)

**1. Credit Behaviour Matters More Than Income**

Overall, how borrowers use credit, or rather, how borrowers can repay or are not repaying credit (credit utilization, repayments, recency,

**2. Credit Grade Is the Strongest Risk Driver**

Clearly, risk increases with each step from Grade A to E.
     Income is no protection in itself from Default Risk.

**3. Moderate Users Are Often Riskier Than Extreme Users**

Borrowers with moderate credit usage (i.e., not very low, not very high) exhibited unexpected stress signals.

**4. Recent Delinquency Is a Major Early Warning Signal** 

Proportion of risk is highly elevated for recent missed payments, but then drops substantially for the 24-month history of on-time payments. 

**5. Some Small Borrower Segments are Highly Toxic**

Low Income + Grade E borrowers, and Delinquent + High Utilization borrowers exhibited extremely high levels of risk concentration.

---

## Final Strategic Recommendations

**1. Grow Portfolio in Stable Segments**

Target Grades A to C, with higher income borrowers and large loan sizes, which have the highest stability.

**2. Apply Tighter Controls on High Stress Borrowers**

Borrowers with utilization over 75%, recent delinquencies, or severe credit occurrences need more scrutiny during the approval process and monitoring stages.

**3. Re-price Middle Risk Grades (C & D)**

These grades have significant risk but are slightly underpriced relative to the risk exposure.

**4. Move From Demographic-Based Risk to Behaviour-Based Risk**

Credit behaviour, the consistency of repayments, and the recency of any late repayments should be more significant factors than income alone.

**5. Monitor High-Risk Combinations, Not Just Individual Factors**

Certain risk concentrations occur, that is, particular combinations like Low Income/Grade E, High Income/Mid Grades, etc., exist. 

 ## Final Reflection 
 This project allowed me to understand lending risk in the real world. From cleaning raw data to applying risk signal development, writing analysis SQL, validating the data output, and extracting business insights, this was an end-to-end learning experience for me. I must admit, I am proud of this project. I set out with the initial goal of working with data, and it evolved
