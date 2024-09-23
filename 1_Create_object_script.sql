CREATE DATABASE POI;
GO


CREATE SCHEMA poi;
GO

CREATE SCHEMA logs;
GO


CREATE SCHEMA stg;
GO


IF OBJECT_ID('poi.d_category', 'U') IS NOT NULL
DROP TABLE poi.d_category;

CREATE TABLE poi.d_category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    top_category_name VARCHAR(255), 
	sub_category_name VARCHAR(255)
);

IF OBJECT_ID('poi.d_tag', 'U') IS NOT NULL
DROP TABLE poi.d_tag;

CREATE TABLE poi.d_tag (
    tag_id INT IDENTITY(1,1) PRIMARY KEY,
    tag_name VARCHAR(255),
	category_id INT
	FOREIGN KEY (category_id) REFERENCES poi.d_category(category_id)
);

IF OBJECT_ID('poi.sub_category_x_tag', 'U') IS NOT NULL
DROP TABLE poi.sub_category_x_tag;


CREATE TABLE poi.category_x_tag (
    category_id INT,
    tag_id INT,
	PRIMARY KEY (category_id, tag_id),
	FOREIGN KEY (category_id) REFERENCES poi.d_category(category_id),
	FOREIGN KEY (tag_id) REFERENCES poi.d_tag(tag_id)
);


IF OBJECT_ID('poi.d_brand', 'U') IS NOT NULL
DROP TABLE poi.d_brand;

CREATE TABLE poi.d_brand(
    brand_id VARCHAR(255) PRIMARY KEY,
    brand_name VARCHAR(255)
);


IF OBJECT_ID('poi.d_region', 'U') IS NOT NULL
DROP TABLE poi.d_region;

CREATE TABLE poi.d_region(
    region_id INT IDENTITY(1,1) PRIMARY KEY,
	postal_code VARCHAR(20),
    city VARCHAR(150),
	region varchar (30),
	country_code varchar(10)
	);

	
IF OBJECT_ID('poi.d_geometry_type', 'U') IS NOT NULL
DROP TABLE poi.d_geometry_type;

CREATE TABLE poi.d_geometry_type(
    geometry_type_id INT IDENTITY(1,1) PRIMARY KEY,
    geometry_type_name varchar(100)
	);

	
IF OBJECT_ID('poi.f_location', 'U') IS NOT NULL
DROP TABLE poi.f_location;

CREATE TABLE poi.f_location (
    id varchar(50) PRIMARY KEY,
	parent_id varchar(50),
	category_id int, 
	region_id int,
    location_name VARCHAR(255),
	longitude float,
	latitude float,
	geometry_type_id int, 
	polygon_wkt text,
	operation_hours text, 
	
    FOREIGN KEY (region_id) REFERENCES poi.d_region(region_id),
    FOREIGN KEY (category_id) REFERENCES poi.d_category(category_id),
    FOREIGN KEY (geometry_type_id) REFERENCES poi.d_geometry_type(geometry_type_id)
);


IF OBJECT_ID('poi.brand_x_location', 'U') IS NOT NULL
DROP TABLE poi.brand_x_location;

CREATE TABLE poi.brand_x_location(
    brand_id VARCHAR(255),
    location_id VARCHAR(50),
	PRIMARY KEY (brand_id, location_id),
	FOREIGN KEY (brand_id) REFERENCES poi.d_brand(brand_id),
	FOREIGN KEY (location_id) REFERENCES poi.f_location(id)
);


CREATE INDEX idx_category_id ON poi.d_category (category_id);

CREATE INDEX idx_tag_category ON poi.d_tag (category_id);
CREATE INDEX idx_tag_id ON poi.d_tag (tag_id);

CREATE INDEX idx_brand_id ON poi.d_brand (brand_id);

CREATE INDEX idx_region_id ON poi.d_region (region_id);

CREATE INDEX idx_location_category ON poi.f_location (category_id);
CREATE INDEX idx_location_region ON poi.f_location (region_id);
CREATE INDEX idx_location_geometry ON poi.f_location (geometry_type_id);

CREATE INDEX idx_brand_location ON poi.brand_x_location (brand_id, location_id);


