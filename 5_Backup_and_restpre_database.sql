BACKUP DATABASE POI TO DISK = N'C:\Backup\POI.bak' WITH COPY_ONLY, NOFORMAT, INIT, NAME = N'POI-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10

use master
ALTER DATABASE POI SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

RESTORE DATABASE POI FROM  DISK =  N'C:\Backup\POI.bak'  WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
