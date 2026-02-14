/*
============================================================
Procedure Name : bronze.load_bronze
Layer          : Bronze (Raw Ingestion Layer)
Architecture   : Medallion Data Warehouse (Bronze → Silver → Gold)

Purpose:
    This stored procedure performs a full refresh load of the
    Bronze Layer tables by applying the following strategy:

        1. TRUNCATE existing data
        2. BULK INSERT fresh data from CSV source files

Process Overview:
    - Loads CRM source tables:
        • bronze.crm_cust_info
        • bronze.crm_prd_info
        • bronze.crm_sales_details

    - Loads ERP source tables:
        • bronze.erp_cut_az12
        • bronze.erp_loc_a101
        • bronze.erp_px_cat_g1v2

Logging & Monitoring:
    - Captures load start/end timestamps
    - Prints execution duration for each table
    - Prints total batch load duration

Error Handling:
    - Uses TRY...CATCH to capture runtime errors
    - Displays error message and line number

WARNING:
    This procedure truncates Bronze tables before loading.
    All existing data in the Bronze Layer will be permanently deleted.

============================================================
*/
USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [bronze].[load_bronze]    Script Date: 2/14/2026 9:16:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- we choosed the full laod of the data into the tables (TRUNCATE THEN LOAD TO THE DATABASE TABLES)

ALTER   PROCEDURE [bronze].[load_bronze] AS 
BEGIN 
    DECLARE @start_time DATETIME, @end_time DATETIME,@end_time_batch DATETIME,@first_time_batch DATETIME;
	BEGIN TRY
	    SET @first_time_batch=GETDATE();
		PRINT('===========================');
		PRINT('Loading the Bronze Layer');
		PRINT('===========================');
		PRINT('---------------------------');
		PRINT('Start Loading the crm tables')
		PRINT('------------------------------');
		SET @start_time=GETDATE();
		PRINT('>>>>> Truncating Table:bronze.crm_cust_info');
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT('>>>>> Inserting Data Into: bronze.crm_cust_info');
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\lenovo\Desktop\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT('>> Load Duration :'+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds');
		PRINT('--------------------------------------------');
		SET @start_time=GETDATE();
		PRINT('>>>>> Truncating Table:bronze.crm_prd_info');
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT('>>>>> Inserting Data Into: bronze.crm_prd_info');
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\lenovo\Desktop\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT('>> Load Duration :'+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds');
		PRINT('--------------------------------------------');
        SET @start_time=GETDATE();
		PRINT('>>>>> Truncating Table:bronze.crm_sales_details');
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT('>>>>> Inserting Data Into: bronze.crm_sales_details');
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\lenovo\Desktop\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT('>> Load Duration :'+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds');
		PRINT('--------------------------------------------');

		PRINT('---------------------------');
		PRINT('Start Loading the ERP tables')
		PRINT('------------------------------');
		SET @start_time=GETDATE();
		PRINT('>>>>> Truncating Table:bronze.erp_cut_az12');
		TRUNCATE TABLE bronze.erp_cut_az12;
		PRINT('>>>>> Inserting Data Into: bronze.erp_cut_az12');
		BULK INSERT bronze.erp_cut_az12
		FROM 'C:\Users\lenovo\Desktop\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT('>> Load Duration :'+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds');
		PRINT('--------------------------------------------');
		SET @start_time=GETDATE();
		PRINT('>>>>> Truncating Table:bronze.erp_loc_a101');
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT('>>>>> Inserting Data Into: erp_loc_a101');
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\lenovo\Desktop\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT('>> Load Duration :'+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds');
		PRINT('--------------------------------------------');
		SET @start_time=GETDATE();
		PRINT('>>>>> Truncating Table:bronze.erp_px_cat_g1v2');
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT('>>>>> Inserting Data Into: bronze.erp_px_cat_g1v2');
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\lenovo\Desktop\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT('>> Load Duration :'+CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + ' Seconds');
		PRINT('--------------------------------------------');
		SET @end_time_batch=GETDATE();
	PRINT('>> Load Duration For the Batch Layer :'+CAST(DATEDIFF(second,@first_time_batch,@end_time_batch) AS NVARCHAR) + ' Seconds');
	END TRY
	BEGIN CATCH 
	PRINT('===============================');
	PRINT('ERROR OCCURED DURING LOADING BRONZE LAYER.');
	PRINT('Error Message:' + ERROR_MESSAGE());
	PRINT('Error Line:'+ CAST(ERROR_LINE() AS NVARCHAR));
	PRINT('===============================');

	END CATCH

END
