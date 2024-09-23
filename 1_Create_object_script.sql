-- Create Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'POI')
BEGIN
    CREATE DATABASE POI;
END
GO

USE POI;
GO

-- Create Schemas if they don't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'poi')
BEGIN
    EXEC('CREATE SCHEMA poi');
END

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'logs')
BEGIN
    EXEC('CREATE SCHEMA logs');
END

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA stg');
END
GO

-- Drop and Create Tables if they don't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'd_category' AND schema_id = SCHEMA_ID('poi'))
BEGIN
    CREATE TABLE poi.d_category (
        category_id INT IDENTITY(1,1) PRIMARY KEY,
        top_category_name VARCHAR(255), 
        sub_category_name VARCHAR(255)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'd_tag' AND schema_id = SCHEMA_ID('poi'))
BEGIN
    CREATE TABLE poi.d_tag (
        tag_id INT IDENTITY(1,1) PRIMARY KEY,
        tag_name VARCHAR(255),
        category_id INT,
        FOREIGN KEY (category_id) REFERENCES poi.d_category(category_id)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'category_x_tag' AND schema_id = SCHEMA_ID('poi'))
BEGIN
    CREATE TABLE poi.category_x_tag (
        category_id INT,
        tag_id INT,
        PRIMARY KEY (category_id, tag_id),
        FOREIGN KEY (category_id) REFERENCES poi.d_category(category_id),
        FOREIGN KEY (tag_id) REFERENCES poi.d_tag(tag_id)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'd_brand' AND schema_id = SCHEMA_ID('poi'))
BEGIN
    CREATE TABLE poi.d_brand (
        brand_id VARCHAR(255) PRIMARY KEY,
        brand_name VARCHAR(255)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'd_region' AND schema_id = SCHEMA_ID('poi'))
BEGIN
    CREATE TABLE poi.d_region (
        region_id INT IDENTITY(1,1) PRIMARY KEY,
        postal_code VARCHAR(20),
        city VARCHAR(150),
        region VARCHAR(30),
        country_code VARCHAR(10)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'd_geometry_type' AND schema_id = SCHEMA_ID('poi'))
BEGIN
    CREATE TABLE poi.d_geometry_type (
        geometry_type_id INT IDENTITY(1,1) PRIMARY KEY,
        geometry_type_name VARCHAR(100)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'f_location' AND schema_id = SCHEMA_ID('poi'))
BEGIN
    CREATE TABLE poi.f_location (
        id VARCHAR(50) PRIMARY KEY,
        parent_id VARCHAR(50),
        category_id INT, 
        region_id INT,
        location_name VARCHAR(255),
        longitude FLOAT,
        latitude FLOAT,
        geometry_type_id INT, 
        polygon_wkt TEXT,
        operation_hours TEXT, 
        FOREIGN KEY (region_id) REFERENCES poi.d_region(region_id),
        FOREIGN KEY (category_id) REFERENCES poi.d_category(category_id),
        FOREIGN KEY (geometry_type_id) REFERENCES poi.d_geometry_type(geometry_type_id)
    );
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'brand_x_location' AND schema_id = SCHEMA_ID('poi'))
BEGIN
    CREATE TABLE poi.brand_x_location (
        brand_id VARCHAR(255),
        location_id VARCHAR(50),
        PRIMARY KEY (brand_id, location_id),
        FOREIGN KEY (brand_id) REFERENCES poi.d_brand(brand_id),
        FOREIGN KEY (location_id) REFERENCES poi.f_location(id)
    );
END

-- Create Indexes if they don't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_category_id' AND object_id = OBJECT_ID('poi.d_category'))
BEGIN
    CREATE INDEX idx_category_id ON poi.d_category (category_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_tag_category' AND object_id = OBJECT_ID('poi.d_tag'))
BEGIN
    CREATE INDEX idx_tag_category ON poi.d_tag (category_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_tag_id' AND object_id = OBJECT_ID('poi.d_tag'))
BEGIN
    CREATE INDEX idx_tag_id ON poi.d_tag (tag_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_brand_id' AND object_id = OBJECT_ID('poi.d_brand'))
BEGIN
    CREATE INDEX idx_brand_id ON poi.d_brand (brand_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_region_id' AND object_id = OBJECT_ID('poi.d_region'))
BEGIN
    CREATE INDEX idx_region_id ON poi.d_region (region_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_location_category' AND object_id = OBJECT_ID('poi.f_location'))
BEGIN
    CREATE INDEX idx_location_category ON poi.f_location (category_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_location_region' AND object_id = OBJECT_ID('poi.f_location'))
BEGIN
    CREATE INDEX idx_location_region ON poi.f_location (region_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_location_geometry' AND object_id = OBJECT_ID('poi.f_location'))
BEGIN
    CREATE INDEX idx_location_geometry ON poi.f_location (geometry_type_id);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_brand_location' AND object_id = OBJECT_ID('poi.brand_x_location'))
BEGIN
    CREATE INDEX idx_brand_location ON poi.brand_x_location (brand_id, location_id);
END
