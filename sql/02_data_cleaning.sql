/*
===============================================================================
  Nashville Housing — Data Cleaning
-------------------------------------------------------------------------------
  Source table : dbo.NashvilleHousing  (database: PortfolioProject)
  Purpose      : Transform raw Nashville housing sales data into an
                 analysis-ready table — standardize the sale date, populate
                 missing addresses, split composite address fields, normalize
                 the "Sold as Vacant" flag, remove duplicate sales, and drop
                 redundant columns.
  Note         : Designed to run once, top to bottom, against a freshly
                 imported table. Each step modifies the table in place, so the
                 script is not intended to be re-run on an already-cleaned table.
===============================================================================
*/

USE PortfolioProject;
GO


------------------------------------------------------------
-- 0. Initial look at the raw data
------------------------------------------------------------

SELECT *
FROM dbo.NashvilleHousing;


------------------------------------------------------------
-- 1. Standardize the sale date
-- SaleDate is imported as text (e.g. "April 09, 2013"); convert it to a
-- clean, consistent DATE value.
------------------------------------------------------------

-- Preview
SELECT SaleDate, CONVERT(DATE, SaleDate) AS Cleaned
FROM dbo.NashvilleHousing;

-- Apply
UPDATE dbo.NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate);


------------------------------------------------------------
-- 2. Populate missing property addresses
-- A ParcelID always maps to the same property address. Where one row for a
-- ParcelID has a NULL address, copy it from another row that shares the same
-- ParcelID (a self-join). ISNULL(a, b) returns b when a is NULL.
------------------------------------------------------------

-- Preview the fix
SELECT a.ParcelID, a.PropertyAddress,
       b.ParcelID, b.PropertyAddress,
       ISNULL(a.PropertyAddress, b.PropertyAddress) AS FilledAddress
FROM dbo.NashvilleHousing AS a
JOIN dbo.NashvilleHousing AS b
    ON  a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Apply
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing AS a
JOIN dbo.NashvilleHousing AS b
    ON  a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


------------------------------------------------------------
-- 3. Split PropertyAddress into (Address, City)
-- PropertyAddress is stored as "street, city". Locate the comma with
-- CHARINDEX and cut the string on either side of it with SUBSTRING.
------------------------------------------------------------

-- Preview
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)                    AS SplitAddress,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS SplitCity
FROM dbo.NashvilleHousing;

-- Add columns
ALTER TABLE dbo.NashvilleHousing ADD PropertySplitAddress NVARCHAR(255);
ALTER TABLE dbo.NashvilleHousing ADD PropertySplitCity    NVARCHAR(255);

-- Populate
UPDATE dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

UPDATE dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


------------------------------------------------------------
-- 4. Split OwnerAddress into (Address, City, State)
-- OwnerAddress has three comma-separated parts. PARSENAME splits on periods,
-- so first REPLACE commas with periods. PARSENAME counts from the right, so
-- position 3 = address, 2 = city, 1 = state.
------------------------------------------------------------

-- Preview
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitState
FROM dbo.NashvilleHousing;

-- Add columns
ALTER TABLE dbo.NashvilleHousing ADD OwnerSplitAddress NVARCHAR(255);
ALTER TABLE dbo.NashvilleHousing ADD OwnerSplitCity    NVARCHAR(255);
ALTER TABLE dbo.NashvilleHousing ADD OwnerSplitState   NVARCHAR(255);

-- Populate
UPDATE dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


------------------------------------------------------------
-- 5. Standardize the "Sold as Vacant" field (Y/N -> Yes/No)
-- The column mixes "Y"/"N" with "Yes"/"No". Normalize everything to Yes/No.
------------------------------------------------------------

-- Preview
SELECT SoldAsVacant,
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
         WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
    END AS Cleaned
FROM dbo.NashvilleHousing;

-- Apply
UPDATE dbo.NashvilleHousing
SET SoldAsVacant =
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
         WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
    END;


------------------------------------------------------------
-- 6. Remove duplicate records
-- Duplicates are rows describing the same sale (same parcel, address, price,
-- date, and legal reference). ROW_NUMBER numbers rows within each such group,
-- giving the first row 1 and any duplicate 2+. A CTE is used because a window
-- function can't be filtered directly in a WHERE clause.
------------------------------------------------------------

-- Preview the duplicates
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Delete the duplicates
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;


------------------------------------------------------------
-- 7. Drop unused columns
-- Remove the original composite address columns (now split into their own
-- columns) and TaxDistrict, which isn't needed for analysis.
------------------------------------------------------------

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;


------------------------------------------------------------
-- Final result — cleaned, analysis-ready table
------------------------------------------------------------

SELECT *
FROM dbo.NashvilleHousing;