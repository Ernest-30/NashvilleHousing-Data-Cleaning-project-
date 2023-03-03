USE NashvilleHousing
SELECT*
FROM Nashville
----------------------------------------------------------------------------------------------------------------------------------------------------------
--Date normalization

ALTER TABLE NASHVILLE
ADD Sale_Date DATE;

UPDATE Nashville
SET Sale_Date = CONVERT(DATE,saledate)

--------------------------------------------------------------------------------------------------------------------------------------------------------------
--Populating the NULL values in propertyAddress

--Step 1

SELECT A.ParcelID, B.ParcelID, A.PropertyAddress, B.PropertyAddress, ISNULL (A.propertyaddress, B.propertyaddress)
FROM Nashville A
JOIN Nashville B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

--Step 2

UPDATE A
SET PropertyAddress = ISNULL (A.propertyaddress, B.propertyaddress)
FROM Nashville A
JOIN Nashville B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Splitting the PropertyAddress

--Step 1

SELECT SUBSTRING (PropertyAddress, 1, CHARINDEX (',', propertyAddress)-1) AS SplitAddress,
		SUBSTRING (PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN (PropertyAddress)) AS SplitCity
FROM Nashville

--Step 2

ALTER TABLE NASHVILLE
ADD PropertySplitAddress NVARCHAR (255);

UPDATE Nashville
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX (',', propertyAddress)-1)

--Step 3
ALTER TABLE NASHVILLE
ADD PropertysplitCIty NVARCHAR (255);

UPDATE Nashville
SET PropertysplitCIty = SUBSTRING (PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN (PropertyAddress))

-------------------------------------------------------------------------------------------------------------------------------------------------
--Splitting the OwnerAddress

--Step 1

SELECT PARSENAME(REPLACE(owneraddress,',','.'), 3) AS SplitOwnerAddress,
	    PARSENAME(REPLACE(owneraddress,',','.'), 2)AS SplitOwnerCity,
		PARSENAME(REPLACE(owneraddress,',','.'), 1) AS SplitOwnerState
FROM Nashville

--Step 2

ALTER TABLE NASHVILLE
ADD OwnersplitAddress NVARCHAR (255);

UPDATE Nashville
SET OwnersplitAddress = PARSENAME(REPLACE(owneraddress,',','.'), 3)

--Step 3

ALTER TABLE NASHVILLE
ADD OwnersplitCIty NVARCHAR (255);

UPDATE Nashville
SET OwnersplitCIty = PARSENAME(REPLACE(owneraddress,',','.'), 2)

--Step 4

ALTER TABLE NASHVILLE
ADD OwnersplitState NVARCHAR (255);

UPDATE Nashville
SET OwnersplitState = PARSENAME(REPLACE(owneraddress,',','.'), 1)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Change Y and N to Yes and No in 'Sold as Vacant' Field

--Step 1

SELECT SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
			 ELSE SoldAsVacant
			 END
FROM Nashville

--Step 2

UPDATE Nashville
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
			 ELSE SoldAsVacant
			 END

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Deleting Duplicates

--Step 1: identify duplicates

SELECT*
FROM (SELECT *, ROW_NUMBER () OVER 
				(PARTITION BY ParcelID,PropertyAddress,
				SalePrice,LegalReference 
				ORDER BY UniqueID) AS row_num
FROM Nashville) N
WHERE N.row_num > 1

--Step 2: Delete Duplicates

DELETE
FROM Nashville
WHERE [UniqueID ] IN
					(SELECT [UniqueID ]
					 FROM (SELECT *,
							ROW_NUMBER () OVER 
							(PARTITION BY ParcelID,PropertyAddress,
							SalePrice, LegalReference
							ORDER BY UniqueID) AS row_num
FROM Nashville) N
WHERE N.row_num > 1)
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Deleting Unsued Columns

ALTER TABLE Nashville
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict

SELECT *
FROM Nashville