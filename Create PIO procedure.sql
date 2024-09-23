IF OBJECT_ID('poi.GetPOIs', 'P') IS NOT NULL
    DROP PROCEDURE poi.GetPOIs;
GO

CREATE PROCEDURE poi.GetPOIs
    @SearchCriteria NVARCHAR(MAX) -- JSON input
AS
BEGIN
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @GeoJSON NVARCHAR(MAX);
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @DurationMilliseconds INT;
    DECLARE @Success BIT = 0; 

    BEGIN TRY
        -- Declare variables to hold parsed JSON values
        DECLARE @CountryCode VARCHAR(10) = NULL,
                @RegionCode VARCHAR(30) = NULL,
                @CityName VARCHAR(150) = NULL,
                @CurrentLongitude FLOAT = -112.0740, -- dummy Phoenix
                @CurrentLatitude FLOAT = 33.4484, -- dummy for Phoenix
                @Radius FLOAT = 200.0,
                @WKTPolygon NVARCHAR(MAX) = NULL,
                @CategoryID INT = NULL,
                @POIName VARCHAR(255) = NULL;

        -- Parse JSON input
        IF JSON_VALUE(@SearchCriteria, '$.country') IS NOT NULL
            SET @CountryCode = JSON_VALUE(@SearchCriteria, '$.country');

        IF JSON_VALUE(@SearchCriteria, '$.region') IS NOT NULL
            SET @RegionCode = JSON_VALUE(@SearchCriteria, '$.region');

        IF JSON_VALUE(@SearchCriteria, '$.city') IS NOT NULL
            SET @CityName = JSON_VALUE(@SearchCriteria, '$.city');

        IF JSON_VALUE(@SearchCriteria, '$.radius') IS NOT NULL
            SET @Radius = JSON_VALUE(@SearchCriteria, '$.radius');

        IF JSON_VALUE(@SearchCriteria, '$.wkt_polygon') IS NOT NULL
            SET @WKTPolygon = JSON_VALUE(@SearchCriteria, '$.wkt_polygon');

        IF JSON_VALUE(@SearchCriteria, '$.category') IS NOT NULL
            SET @CategoryID = JSON_VALUE(@SearchCriteria, '$.category');

        IF JSON_VALUE(@SearchCriteria, '$.name') IS NOT NULL
            SET @POIName = JSON_VALUE(@SearchCriteria, '$.name');

        IF @Radius < 0
            THROW 50001, 'Radius cannot be negative.', 1;

        -- Base query
        DECLARE @SQL NVARCHAR(MAX) = 'SELECT 
            loc.id,
            loc.parent_id,
            reg.country_code,
            reg.region,
            reg.city,
            loc.latitude,
            loc.longitude,
            cat.top_category_name AS category,
            cat.sub_category_name AS sub_category,
            loc.polygon_wkt,
            loc.location_name,
            reg.postal_code,
            loc.operation_hours
        FROM poi.f_location loc
        JOIN poi.d_region reg ON loc.region_id = reg.region_id
        LEFT JOIN poi.d_category cat ON loc.category_id = cat.category_id
        WHERE 1=1';
		  
		 
        IF @CountryCode IS NOT NULL
            SET @SQL += ' AND reg.country_code = @CountryCode';

        IF @RegionCode IS NOT NULL
            SET @SQL += ' AND reg.region = @RegionCode';

        IF @CityName IS NOT NULL
            SET @SQL += ' AND reg.city = @CityName';

        -- Distance filter if location is given
        SET @SQL += ' AND (6371 * acos(cos(radians(@CurrentLatitude)) * cos(radians(loc.latitude)) 
            * cos(radians(loc.longitude) - radians(@CurrentLongitude)) + sin(radians(@CurrentLatitude)) 
            * sin(radians(loc.latitude)))) <= @Radius';

        -- WKT Polygon filter if provided
        IF @WKTPolygon IS NOT NULL
            SET @SQL += ' AND loc.polygon_wkt.STIntersects(geometry::STGeomFromText(@WKTPolygon, 4326)) = 1';

        IF @CategoryID IS NOT NULL
            SET @SQL += ' AND loc.category_id = @CategoryID';

        IF @POIName IS NOT NULL
            SET @SQL += ' AND loc.location_name LIKE ''%'' + @POIName + ''%''' ;

        -- Create GeoJSON result
        SET @SQL += '
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER';

        -- Execute the dynamic SQL

        EXEC @GeoJSON = sp_executesql @SQL,
            N'@CountryCode VARCHAR(10), @RegionCode VARCHAR(30), @CityName VARCHAR(150), 
              @CurrentLongitude FLOAT, @CurrentLatitude FLOAT, @Radius FLOAT, 
              @WKTPolygon NVARCHAR(MAX), @CategoryID INT, @POIName VARCHAR(255)',
            @CountryCode, @RegionCode, @CityName, @CurrentLongitude, @CurrentLatitude, 
            @Radius, @WKTPolygon, @CategoryID, @POIName;

        -- Check if any results were returned
        IF @GeoJSON IS NULL
            THROW 50002, 'No points of interest found for the given criteria.', 1;

        -- If execution reaches here, it was successful
        SET @Success = 1;

        SELECT @GeoJSON AS GeoJSON;

    END TRY
    BEGIN CATCH
        -- Capture error information
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorState = ERROR_STATE();

        -- Log the error
        INSERT INTO logs.ExecutionLog (ProcedureName, ExecutionTime, Success, ErrorMessage)
        VALUES ('poi.GetPOIs', GETDATE(), 0, @ErrorMessage);

        
        SELECT @ErrorMessage AS ErrorMessage, 
               @ErrorSeverity AS ErrorSeverity, 
               @ErrorState AS ErrorState;

        RETURN; 
    END CATCH

    -- Log successful execution
    SET @DurationMilliseconds = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
    INSERT INTO logs.ExecutionLog (ProcedureName, ExecutionTime, DurationMilliseconds, Success)
    VALUES ('poi.GetPOIs', GETDATE(), @DurationMilliseconds, @Success);
END;


----------------------/  ************* PROCEDURE EXECUTION *************   / ------------------------------


DECLARE @SearchCriteria NVARCHAR(MAX) = 
'{
    "country": "US",
    "region": "AZ",
    "city": "Phoenix",
    "radius": 100,
    "category": 216,
    "name": "Progrexion"
}';

EXEC poi.GetPOIs @SearchCriteria;


DECLARE @SearchCriteria NVARCHAR(MAX) = '{}'; 

EXEC poi.GetPOIs @SearchCriteria;
