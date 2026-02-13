/*
Script Purpose:
	This script creates a new database named 'DataWarehouse' after checking if it already exists.
	if the database exists , it is dropped and recreated.Additionally, the script sets up three schemas
	within the database. 'bronze' , 'silver' , 'gold
WARNING:
	Running this script will drop the entire database if exists.
	All the data will be permanently deleted.
*/
USE master;
-- check if the database already exists and then drops it 
IF EXISTS (SELECT 1 FROM sys.databases WHERE name='DataWarehouse')
BEGIN 
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO
-- Create the database
CREATE DATABASE DataWarehouse;
USE DataWarehouse;
GO
-- Creating The Schemas For Each Layer (Bronze-Silver-Gold)
Create SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;

