

# 📊 Sales Data Cleaning & Analytics Project

## 🚀 Overview
This project is an end-to-end SQL data pipeline designed to clean, transform, and analyze a financial sales dataset. It demonstrates a complete data analytics workflow using SQL only — from raw data ingestion to generating actionable business insights.

---

## 🛠️ Tools & Technologies
* **Database:** PostgreSQL[cite: 1]
* **SQL Techniques:** CTEs, Window Functions, Aggregations, Data Cleaning, and Regex[cite: 1]
* **Environment:** pgAdmin 4

---

## 🔄 Project Workflow

### 1. Data Ingestion
* Created raw sales table from the dataset.
* Backed up original data to preserve raw input[cite: 1].
**![Raw Data Structure](1.png)**[cite: 1]

### 2. Data Cleaning & Standardization
* Removed irrelevant and corrupted columns.
* Renamed columns for consistency and readability[cite: 1].
* Standardized schema structure.
**![Column Standardization](2.png)**[cite: 1]

### 3. Feature Engineering & Type Casting
* Recalculated key financial metrics: **Total Sales, Revenue, Profit, Cost**[cite: 1].
* Converted columns from `TEXT` to appropriate numeric and date types to ensure consistency[cite: 1].
**![Feature Engineering](5.png)**[cite: 1]

### 4. Data Quality Assurance
* Replaced NULL categorical values with `"Unknown"`.
* Applied average imputation for numeric fields.
* Verified zero NULL values across all critical columns after the cleaning process[cite: 1].
**![Data Quality Check](15.png)**[cite: 1]

### 5. Final Dataset
* Created a clean analytical table: `sales_clean` optimized for reporting[cite: 1].

---

## 📈 Key KPIs & Insights
* **Total Revenue & Profit:** Extracted core business metrics[cite: 1].
* **Regional Performance:** Identified that the USA leads in revenue while Germany shows higher profit efficiency[cite: 1].
**![Main KPIs](18.png)**[cite: 1]

---

## 💡 Analysis Performed
* **Country Analysis:** Analyzing performance by market[cite: 1].
* **Product Analysis:** Identifying high-volume vs. high-margin products[cite: 1].
* **Pareto (80/20) Analysis:** Understanding revenue contribution.
**![Regional Analysis](21.png)**[cite: 1]

---

## 🎯 Project Objective
To demonstrate real-world SQL capabilities in building data cleaning pipelines, performing business analysis, and extracting actionable insights for decision-making[cite: 1].

---

## 👨‍💻 Author
**Omar Essam**[cite: 1]

---

### ⚠️ ملحوظة مهمة جداً يا عمر:
بناءً على الصورة (image_4ba973.png)، لازم تعمل الخطوات دي عشان الكود يشتغل:
1.  **تغيير اسم الملف:** لازم تخلي اسم الملف `README.md` (شيل كلمة `.txt` من الآخر)[cite: 1].
2.  **حذف الصور القديمة:** يفضل تمسح الصور من الصفحة الرئيسية لو هتعمل فولدر `image` زي ما قولنا قبل كده، بس لو هتسيبهم بره يبقى الكود اللي فوق ده هو اللي هيشغلهم[cite: 1].
