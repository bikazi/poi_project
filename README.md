Set up enviroment:
1- execute 1_Create_object_script to create database, schemas, tables and indexes. This script organizes all tables into three schemas:
     a) POI Schema: This is the main reporting schema.
     b) STG Schema: This serves as the staging area for the phoenix.csv file and other raw files.
     c) Logs Schema: This schema contains two tables for error logs and execution logs.
2- import raw phoenix file https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-flat-file-wizard?view=sql-server-ver16
3 - execute 3_Insert_into_script for data migration from stg phoenix file to database
4- execute 4_create_poi_procedure to create procedure GetPoi. This procedure returns data in JSON format. At the end of the script, you will find examples of execution using dummy parameters, as well as an execution that returns all rows.
5_Backup_and_restore doing backup and restore POI database. You need to set up backup/restore location.
