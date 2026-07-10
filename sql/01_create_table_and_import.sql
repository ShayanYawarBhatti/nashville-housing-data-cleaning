USE PortfolioProject;
GO

DROP TABLE IF EXISTS dbo.NashvilleHousing;
GO

CREATE TABLE dbo.NashvilleHousing (
    UniqueID        NVARCHAR(50),
    ParcelID        NVARCHAR(50),
    LandUse         NVARCHAR(100),
    PropertyAddress NVARCHAR(255),
    SaleDate        NVARCHAR(50),
    SalePrice       NVARCHAR(50),
    LegalReference  NVARCHAR(100),
    SoldAsVacant    NVARCHAR(50),
    OwnerName       NVARCHAR(255),
    OwnerAddress    NVARCHAR(255),
    Acreage         NVARCHAR(50),
    TaxDistrict     NVARCHAR(100),
    LandValue       NVARCHAR(50),
    BuildingValue   NVARCHAR(50),
    TotalValue      NVARCHAR(50),
    YearBuilt       NVARCHAR(50),
    Bedrooms        NVARCHAR(50),
    FullBath        NVARCHAR(50),
    HalfBath        NVARCHAR(50)
);
GO

BULK INSERT dbo.NashvilleHousing
FROM '/var/opt/mssql/import/nashville_housing.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

SELECT COUNT(*) AS TotalRows FROM dbo.NashvilleHousing;
SELECT TOP 10 * FROM dbo.NashvilleHousing;
GO