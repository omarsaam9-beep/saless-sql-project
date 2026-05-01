 📊 Sales Data Cleaning & Analytics Project

🚀 Overview

This project is an end-to-end SQL data pipeline designed to clean, transform, and analyze a financial sales dataset.

It demonstrates a complete data analytics workflow using SQL only — from raw data ingestion to generating actionable business insights.

---

 🛠️ Tools & Technologies

* PostgreSQL
* SQL (CTEs, Window Functions, Aggregations)
* Data Cleaning Techniques
* Analytical Thinking

---

 🔄 Project Workflow

 1. Data Ingestion

* Created raw sales table from the dataset
* Backed up original data to preserve raw input

 2. Data Cleaning

* Removed irrelevant and corrupted columns
* Renamed columns for consistency and readability
* Standardized schema structure

 3. Feature Engineering

* Recalculated key financial metrics:

  * Total Sales
  * Revenue
  * Profit
  * Cost
* Ensured consistency across all calculations

 4. Handling Missing Values

* Replaced NULL categorical values with `"Unknown"`
* Applied average imputation for numeric fields
* Used forward-fill and backward-fill techniques for missing dates

 5. Data Standardization

* Removed special characters from text fields
* Converted columns to appropriate data types
* Cleaned numeric values using regex

 6. Final Dataset

* Created a clean analytical table: `sales_clean`
* Optimized for analysis and reporting

---

 📈 Key KPIs

* Total Revenue
* Total Profit
* Profit Margin %
* Total Discounts
* Discount Leakage %
* Average Order Value
* Total Units Sold

---

 💡 Key Insights

* The United States leads in revenue, while Germany shows higher profitability efficiency
* The *Montana* product generates high sales volume but low profit margins
* High discount levels significantly reduce overall profitability
* Some countries generate strong revenue but operate with low efficiency

---

 📊 Analysis Performed

* Country performance analysis
* Product performance analysis
* Discount impact analysis
* Segment profitability analysis
* Time-based trend analysis
* Pareto (80/20) revenue analysis

---

🎯 Project Objective

To demonstrate real-world SQL capabilities in:

* Building data cleaning pipelines
* Performing business analysis
* Generating KPIs
* Extracting actionable insights for decision-making

---

 👨‍💻 Author

Omar Essam