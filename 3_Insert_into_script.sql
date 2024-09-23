

INSERT INTO poi.d_category (top_category_name, sub_category_name)

SELECT  distinct top_category, sub_category
from stg.phoenix
where top_category is not null


MERGE poi.d_tag AS target
USING (
  SELECT c.category_id,
         p.category_tag
  FROM (
    SELECT 
        p.top_category, 
        value AS category_tag
    FROM 
        stg.phoenix p
    CROSS APPLY STRING_SPLIT(p.category_tags, ',') AS split_ids
    WHERE p.category_tags IS NOT NULL
  ) AS p
 LEFT JOIN poi.d_category c ON c.top_category_name = p.top_category  
) AS source  
ON target.category_id = source.category_id AND target.tag_name = source.category_tag
WHEN MATCHED THEN
    UPDATE SET 
        target.category_id = source.category_id
WHEN NOT MATCHED THEN
    INSERT (category_id, tag_name)
    VALUES (source.category_id, source.category_tag);
	

	INSERT INTO poi.d_brand (brand_id, brand_name)
	SELECT DISTINCT BRAND_ID, BRAND
	FROM stg.phoenix
	WHERE brand_id NOT LIKE '%,%'
	AND brand_id IS NOT NULL

	
;WITH SplitData AS (
    SELECT 
        b.value AS brand,
        ROW_NUMBER() OVER (PARTITION BY p.brand_id ORDER BY (SELECT NULL)) AS rn,
        p.brand_id
    FROM stg.phoenix p
    CROSS APPLY STRING_SPLIT(p.BRAND, ',') AS b
	WHERE BRAND_ID LIKE '%,%'
),
SplitBrandIDs AS (
    SELECT 
        id.value AS brand_id_value,
        ROW_NUMBER() OVER (PARTITION BY p.brand_id ORDER BY (SELECT NULL)) AS rn,
        p.brand_id
    FROM stg.phoenix p
    CROSS APPLY STRING_SPLIT(p.brand_id, ',') AS id
	WHERE BRAND_ID LIKE '%,%'
)
INSERT INTO poi.d_brand (brand_id, brand_name)
SELECT DISTINCT
    s.brand_id_value AS brand_id,
    b.brand
	
FROM 
    SplitData b
JOIN 
    SplitBrandIDs s ON b.rn = s.rn AND b.brand_id = s.brand_id
WHERE 
    b.brand IS NOT NULL AND s.brand_id_value IS NOT NULL
AND NOT EXISTS (SELECT * FROM poi.d_brand br
where br.brand_id = s.brand_id_value)

	

insert into poi.d_region (postal_code, region, city, country_code)
select distinct postal_code, region, city, country_code from stg.phoenix

insert into poi.d_geometry_type 
select distinct geometry_type from stg.phoenix


MERGE poi.f_location AS target
USING (
    SELECT 
        p.id,
        p.parent_id,
		p.location_name,
        c.category_id,
		r.region_id,
        p.operation_hours,
		p.latitude,
        p.longitude,   
        gt.geometry_type_id ,
        p.polygon_wkt 
		--select count (*)
    FROM 
        stg.phoenix p
    LEFT JOIN 
        poi.d_category c ON p.top_category = c.top_category_name and isnull(p.sub_category, '') = isnull(c.sub_category_name, '')
	 LEFT JOIN 
        poi.d_region r ON p.postal_code = r.postal_code
					  AND p.city = r.city
					  AND p.country_code = r.country_code
					  AND p.region = r.region 
	LEFT JOIN 
        poi.d_geometry_type gt ON gt.geometry_type_name = p.geometry_type

   
) AS source
ON target.id = source.id 
WHEN MATCHED THEN
    UPDATE SET 
        target.parent_id = source.parent_id,
        target.region_id = source.region_id,
        target.category_id = source.category_id,
        target.geometry_type_id = source.geometry_type_id
WHEN NOT MATCHED THEN
    INSERT (id, parent_id, location_name, region_id, category_id, operation_hours, latitude, longitude, geometry_type_id, polygon_wkt)
    VALUES (source.id, source.parent_id, source.location_name, source.region_id, source.category_id, source.operation_hours, 
	source.latitude, source.longitude, source.geometry_type_id, source.polygon_wkt);


	MERGE poi.brand_x_location AS target
USING (
  SELECT l.id AS location_id,
         b.brand_id
  FROM (
    SELECT 
        p.id, 
        value AS brand_id
    FROM 
        stg.phoenix p
    CROSS APPLY STRING_SPLIT(p.brand_id, ',') AS split_ids
    WHERE p.brand_id IS NOT NULL
  ) AS p
  LEFT JOIN poi.f_location l ON l.id = p.id 
  LEFT JOIN poi.d_brand b ON b.brand_id = p.brand_id
) AS source  
ON target.location_id = source.location_id AND target.brand_id = source.brand_id
WHEN MATCHED THEN
    UPDATE SET 
        target.brand_id = source.brand_id
WHEN NOT MATCHED THEN
    INSERT (location_id, brand_id)
    VALUES (source.location_id, source.brand_id);




	CREATE TABLE logs.ErrorLog (
    ErrorID INT IDENTITY(1,1) PRIMARY KEY,
    ErrorMessage NVARCHAR(4000),
    ErrorSeverity INT,
    ErrorState INT,
    ErrorTime DATETIME DEFAULT GETDATE()
);

CREATE TABLE logs.ExecutionLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ProcedureName NVARCHAR(255),
    ExecutionTime DATETIME DEFAULT GETDATE(),
    DurationMilliseconds INT,
    Success BIT,
    ErrorMessage NVARCHAR(4000) NULL,
    AdditionalInfo NVARCHAR(4000) NULL
);
