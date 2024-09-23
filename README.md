This project consists of:
- POI Database Backup: The backup file is named poi.bak.
- Object Creation Script: This script organizes all tables into three schemas:
     a) POI Schema: This is the main reporting schema.
     b) STG Schema: This serves as the staging area for the phoenix.csv file and other raw files.
     c) Logs Schema: This schema contains two tables for error logs and execution logs.
- POI Procedure: This procedure returns data in JSON format. At the end of the script, you will find examples of execution using dummy parameters, as well as an execution that returns all rows.
