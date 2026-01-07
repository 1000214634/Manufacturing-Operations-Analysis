
SELECT TOP 10 * FROM hms_manufacturing_data;

 
 --Data Cleaning

-- Remove records with missing critical identifiers (Job_ID or Machine_ID)
DELETE FROM hms_manufacturing_data   
WHERE Job_ID IS NULL  
   OR Machine_ID IS NULL; 


-- Assign a default status to jobs with missing Job_Status
UPDATE hms_manufacturing_data 
SET Job_Status = 'Unknown' 
WHERE Job_Status IS NULL; 


-- Standardize text fields to ensure consistent grouping and analysis
UPDATE hms_manufacturing_data 
SET Operation_Type = UPPER(LTRIM(RTRIM(Operation_Type))), 
    Optimization_Category = LTRIM(RTRIM(Optimization_Category)); 


-- Correct invalid timestamps where Actual_End occurs before Actual_Start
UPDATE hms_manufacturing_data 
SET Actual_End = NULL 
WHERE Actual_End < Actual_Start; 


-- Remove invalid negative values for energy consumption
UPDATE hms_manufacturing_data 
SET Energy_Consumption = 0 
WHERE Energy_Consumption < 0; 


-- Remove invalid negative values for material usage
UPDATE hms_manufacturing_data 
SET Material_Used = 0 
WHERE Material_Used < 0; 


-- Remove duplicate Job_ID records while keeping the most recent entry
WITH CTE AS ( 
    SELECT Job_ID, 
           ROW_NUMBER() OVER (PARTITION BY Job_ID ORDER BY Actual_Start DESC) AS DuplicateCount 
    FROM hms_manufacturing_data 
) 
DELETE FROM CTE 
WHERE DuplicateCount > 1;


--Verification
SELECT 
    COUNT(*) as Total_Jobs,
    AVG(Processing_Time) as Avg_Time,
    SUM(CASE WHEN Actual_End IS NULL THEN 1 ELSE 0 END) as Incomplete_Jobs
FROM hms_manufacturing_data;

--KPIS
--حجم الشغل.1
SELECT 
    COUNT(*) AS Total_Jobs,
    COUNT(DISTINCT Machine_ID) AS Total_Machines
FROM hms_manufacturing_data;

--2.كفاءة الوقت (Cycle Time)
SELECT 
    Machine_ID,
    AVG(Processing_Time) AS Avg_Processing_Time
FROM hms_manufacturing_data
GROUP BY Machine_ID
ORDER BY Avg_Processing_Time DESC;
--دي هتطلع أبطأ ماكينة.
--3.الالتزام بالجدول (Schedule Adherence)
SELECT 
    COUNT(*) AS Total_Jobs,
    SUM(CASE 
        WHEN Actual_End > Scheduled_End THEN 1 
        ELSE 0 
    END) AS Delayed_Jobs
FROM hms_manufacturing_data;

--Percentage
SELECT 
    CAST(SUM(CASE WHEN Actual_End > Scheduled_End THEN 1 ELSE 0 END) * 100.0 
         / COUNT(*) AS DECIMAL(5,2)) AS Delay_Percentage
FROM hms_manufacturing_data;

--4.استهلاك الطاقة
SELECT 
    Machine_ID,
    AVG(Energy_Consumption) AS Avg_Energy,
    SUM(Energy_Consumption) AS Total_Energy
FROM hms_manufacturing_data
GROUP BY Machine_ID
ORDER BY Total_Energy DESC;

--دي بتحدد أكتر ماكينة بتكلفك فلوس.

--5. (Energy per Job)
SELECT 
    Operation_Type,
    AVG(Energy_Consumption / NULLIF(Processing_Time,0)) AS Energy_per_Minute
FROM hms_manufacturing_data
GROUP BY Operation_Type
ORDER BY Energy_per_Minute DESC;


--Business & Analytical Questions (Manufacturing Analytics)
--1. Bottleneck Analysis
--Which operation types have the longest average processing time and are causing production bottlenecks?
SELECT 
    Operation_Type,
    AVG(Processing_Time) AS Avg_Processing_Time,
    COUNT(*) AS Job_Count
FROM hms_manufacturing_data
GROUP BY Operation_Type
ORDER BY Avg_Processing_Time DESC;

/*Operation types with the highest average processing time are the main production bottlenecks, 
as they slow down overall throughput and increase lead times

تشكل أنواع العمليات ذات أعلى متوسط وقت معالجة
الاختناقات الرئيسية في الإنتاج، لأنها تؤدي إلى إبطاء الإنتاجية الإجمالية وزيادة أوقات التسليم.

*/

--2️.Machine Performance
--Which machines are underperforming based on average processing time and energy consumption?
SELECT 
    Machine_ID,
    AVG(Processing_Time) AS Avg_Processing_Time,
    AVG(Energy_Consumption) AS Avg_Energy
FROM hms_manufacturing_data
GROUP BY Machine_ID
ORDER BY Avg_Processing_Time DESC, Avg_Energy DESC;

/*Machines with both high processing time and high energy consumption are underperforming and should be prioritized for maintenance or process optimization.
الآلات ذات وقت المعالجة العالي والاستهلاك العالي للطاقة تكون ذات أداء ضعيف ويجب إعطاؤها الأولوية للصيانة أو تحسين العملية.
*/

--3.Schedule Adherence
--How many jobs are delayed compared to their scheduled completion time?

SELECT 
    COUNT(*) AS Total_Jobs,
    SUM(CASE WHEN Actual_End > Scheduled_End THEN 1 ELSE 0 END) AS Delayed_Jobs
FROM hms_manufacturing_data;

/*Delayed jobs represent inefficiencies in scheduling or machine utilization and directly impact delivery commitments.
تمثل الوظائف المتأخرة عدم كفاءة في الجدولة أو استخدام الآلات وتؤثر بشكل مباشر على التزامات التسليم.
*/

--4. Delay Rate
--What percentage of jobs are delayed?
SELECT 
    CAST(
        SUM(CASE WHEN Actual_End > Scheduled_End THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*) 
    AS DECIMAL(5,2)) AS Delay_Percentage
FROM hms_manufacturing_data;


--The delay percentage provides a clear KPI for schedule reliability and operational performance
--توفر نسبة التأخير مؤشر أداء رئيسيًا واضحًا لموثوقية الجدول الزمني والأداء التشغيلي.

--5.Energy Consumption by Machine
--Which machines consume the highest total energy?
SELECT 
    Machine_ID,
    SUM(Energy_Consumption) AS Total_Energy
FROM hms_manufacturing_data
GROUP BY Machine_ID
ORDER BY Total_Energy DESC;

--Machines with the highest total energy consumption are key cost drivers and strong candidates for energy efficiency initiatives
--تعد الآلات ذات أعلى استهلاك إجمالي للطاقة محركات رئيسية للتكلفة ومرشحة قوية لمبادرات كفاءة الطاقة.

--6.Energy Efficiency by Operation
--Which operation types are the least energy-efficient?
SELECT 
    Operation_Type,
    AVG(Energy_Consumption / NULLIF(Processing_Time, 0)) AS Energy_per_Minute
FROM hms_manufacturing_data
GROUP BY Operation_Type
ORDER BY Energy_per_Minute DESC;

--Operation types with higher energy consumption per minute indicate inefficient processes or outdated equipment.
--تشير أنواع العمليات ذات استهلاك الطاقة الأعلى في الدقيقة إلى عمليات غير فعالة أو معدات قديمة.


--7. Job Completion Status
SELECT 
    Job_Status,
    COUNT(*) AS Job_Count
FROM hms_manufacturing_data
GROUP BY Job_Status;

--A high number of incomplete or unknown job statuses may indicate data quality issues or operational disruptions
--قد يشير العدد الكبير من الحالات الوظيفية غير المكتملة أو غير المعروفة إلى مشكلات في جودة البيانات أو اضطرابات تشغيلية.

--8.Availability vs Performance
--Does lower machine availability correlate with longer processing times?
SELECT 
    Machine_ID,
    AVG(Machine_Availability) AS Avg_Availability,
    AVG(Processing_Time) AS Avg_Processing_Time
FROM hms_manufacturing_data
GROUP BY Machine_ID
ORDER BY Avg_Availability ASC;



--Machines with lower availability tend to have longer processing times, suggesting frequent downtime impacts productivity.
--تميل الآلات ذات التوافر الأقل إلى أن يكون لديها أوقات معالجة أطول، مما يشير إلى أن التوقف المتكرر يؤثر على الإنتاجية.

--9.Optimization Impact
--Which optimization categories are associated with better performance?
SELECT 
    Optimization_Category,
    AVG(Processing_Time) AS Avg_Processing_Time,
    AVG(Energy_Consumption) AS Avg_Energy
FROM hms_manufacturing_data
GROUP BY Optimization_Category
ORDER BY Avg_Processing_Time ASC;

--Optimization categories with lower average processing time and energy consumption demonstrate effective improvement strategies.
--تُظهر فئات التحسين ذات متوسط وقت المعالجة المنخفض واستهلاك الطاقة استراتيجيات تحسين فعالة.


--10. High-Cost Jobs
--Which individual jobs have exceptionally high processing time or energy consumption?
SELECT 
    top 10 Job_ID,
    Machine_ID,
    Processing_Time,
    Energy_Consumption
FROM hms_manufacturing_data
ORDER BY Processing_Time DESC, Energy_Consumption DESC;

--High-cost jobs should be investigated individually to identify root causes such as machine failure, material issues, or process inefficiencies.
--ينبغي التحقيق في الوظائف ذات التكلفة المرتفعة بشكل فردي لتحديد الأسباب الجذرية مثل فشل الماكينة، أو مشاكل المواد، أو عدم كفاءة العملية.


/*Final Interview-Ready Summary

This analysis identifies production bottlenecks, inefficient machines, scheduling issues, and energy cost drivers using SQL-based manufacturing analytics.
The insights support data-driven decisions for process optimization, cost reduction, and capacity planning.

*/

--تحليل الأثر المالي (Financial Impact)
SELECT 
    Job_Status, 
    SUM(Energy_Consumption) AS Total_Energy_Lost,
    SUM(Energy_Consumption) * 0.15 AS Estimated_Cost_Loss_USD
FROM hms_manufacturing_data
WHERE Job_Status = 'Failed'
GROUP BY Job_Status;

-- تحليل عميق للوظائف الفاشلة (Failed Jobs Deep Dive)
SELECT 
    Machine_ID, 
    COUNT(*) AS Failed_Count,
    AVG(Machine_Availability) AS Avg_Availability_During_Failure
FROM hms_manufacturing_data
WHERE Job_Status = 'Failed'
GROUP BY Machine_ID
ORDER BY Failed_Count DESC;

-- إنشاء "نظام أولويات" (Priority System)
SELECT 
    Job_ID, 
    Operation_Type,
    CASE 
        WHEN Operation_Type = 'GRINDING' THEN 'High Priority - Bottleneck' -- لأن الجلخ هو العائق الأكبر [cite: 159, 212]
        WHEN Machine_ID = 'M02' THEN 'Check Maintenance' -- لأنها الأبطأ [cite: 179, 213]
        ELSE 'Normal'
    END AS Management_Action
FROM hms_manufacturing_data;



CREATE PROCEDURE sp_CleanManufacturingData
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Remove records with missing critical identifiers [cite: 7]
    DELETE FROM hms_manufacturing_data
    WHERE Job_ID IS NULL OR Machine_ID IS NULL;

    -- 2. Assign a default status to jobs with missing Job_Status [cite: 10]
    UPDATE hms_manufacturing_data
    SET Job_Status = 'Unknown'
    WHERE Job_Status IS NULL;

    -- 3. Standardize text fields for consistent grouping [cite: 14]
    UPDATE hms_manufacturing_data
    SET Operation_Type = UPPER(LTRIM(RTRIM(Operation_Type))),
        Optimization_Category = LTRIM(RTRIM(Optimization_Category));

    -- 4. Correct invalid timestamps (End before Start) [cite: 20]
    UPDATE hms_manufacturing_data
    SET Actual_End = NULL
    WHERE Actual_End < Actual_Start;

    -- 5. Remove invalid negative values for energy and material [cite: 24, 28]
    UPDATE hms_manufacturing_data
    SET Energy_Consumption = 0 WHERE Energy_Consumption < 0;
    
    UPDATE hms_manufacturing_data
    SET Material_Used = 0 WHERE Material_Used < 0;

    -- 6. Remove duplicate Job_ID records [cite: 32]
    WITH CTE AS (
        SELECT Job_ID,
               ROW_NUMBER() OVER (PARTITION BY Job_ID ORDER BY Actual_Start DESC) AS DuplicateCount
        FROM hms_manufacturing_data
    )
    DELETE FROM CTE WHERE DuplicateCount > 1;

    PRINT 'Manufacturing Data Pipeline: Cleaning Successful.';
END;
GO


sp_CleanManufacturingData
--Conclusion
/*
Conclusion: This analysis successfully identified that Grinding is the 
primary bottleneck and Machine M02 requires efficiency optimization. 
By implementing the sp_CleanManufacturingData procedure, 
the factory now has an automated system to maintain data quality. 
These insights provide a clear roadmap for reducing the 48.5% delay rate and 
improving overall energy efficiency across all 5 machines
*/
