# 🏭 Manufacturing Operations Analysis & Data Automation (SQL)

## 1️⃣ Project Overview
This project analyzes **1,000 manufacturing jobs** across 5 machines to identify production bottlenecks, delays, and energy inefficiencies using **SQL**. The goal is to provide actionable insights to improve operational efficiency and reduce costs.

## 2️⃣ Business Problems
* **Production Delays:** Nearly half of all jobs (48.5%) experienced delays, affecting delivery timelines.
* **Operational Bottlenecks:** Certain processes, such as **Grinding**, create bottlenecks and slow down operations.
* **Energy Inefficiency:** Specific machines, like **M03**, are less energy-efficient, increasing operational costs.

## 3️⃣ Tools & Technologies
* **SQL Server 2022** – Used for data cleaning, complex aggregations, and KPI calculation.
* **Stored Procedures** – Developed to automate data pipelines and ensure repeatable analysis.

## 4️⃣ Work Process
1.  **Data Cleaning:** Removed invalid, duplicate, or incomplete records.
2.  **Data Standardization:** Normalized text fields and corrected logical errors (e.g., end dates before start dates).
3.  **KPI Calculation:** Computed key metrics such as delay rates, average processing time, and energy consumption.
4.  **Automation:** Implemented SQL Stored Procedures for scalable and repeatable data processing.
5.  **Insights & Recommendations:** Identified primary bottlenecks and proposed operational improvements.

## 5️⃣ Key Results & Insights
* 🔴 **48.5% Delay Rate:** Indicates significant inefficiency in scheduling or machine capacity.
* ⚙️ **Grinding Bottleneck:** Has the longest average processing time (**73 units**), identifying it as the main production constraint.
* ⚡ **Energy Consumption:** **Machine M03** consumes the most energy (**8.76 units/job**), highlighting a need for maintenance or task redistribution.
* 🤖 **Automation Success:** Stored Procedure integration enables consistent, one-click KPI generation for future data.

## 6️⃣ Recommendations
* **Optimize Grinding Process:** Review workflow and balance workload across machines to reduce delays.
* **Maintain Machine M03:** Schedule preventive maintenance to improve energy efficiency.
* **Job Redistribution:** Move high-energy or slow tasks to more efficient machines.
* **Implement Monitoring:** Use the developed SQL procedures to monitor failed or delayed jobs in real-time.
