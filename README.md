# Nashville Housing — SQL Data Cleaning

Cleaning and standardizing a raw ~56,000-row Nashville housing sales dataset in **Microsoft SQL Server**, turning a messy export into an analysis-ready table.

This project walks through the data analysis lifecycle — **Ask → Prepare → Process → Share** — to mirror how a data problem is actually handled in a workplace, rather than presenting cleaning as an isolated exercise.

---

## Ask — the objective

> *"Before we can analyze Nashville property sales, the raw data export needs to be made reliable. It has inconsistent date formats, missing addresses, combined address fields that can't be filtered or grouped, inconsistent categorical values, and duplicate sale records. Make it analysis-ready."*

The goal: produce a clean, consistent, de-duplicated table that an analyst or BI tool could query with confidence.

---

## Prepare — the data

- **Source:** Nashville housing sales export (`data/Nashville Housing Data for Data Cleaning.xlsx`), ~56,477 rows.
- **Environment:** Microsoft SQL Server 2022 running in Docker on macOS, queried through VS Code (mssql extension).
- **Import approach:** Rather than let the importer guess column types (which mangled the schema), I created a staging table with every column typed as `NVARCHAR` and bulk-loaded into it. This guaranteed a clean load; correct types are then derived during cleaning.

**Data quality issues identified:**

| Issue | Column(s) | Fix |
|---|---|---|
| Dates stored as free text | `SaleDate` | Convert to a proper `DATE` |
| Missing property addresses | `PropertyAddress` | Populate via self-join on `ParcelID` |
| Street + city combined in one field | `PropertyAddress` | Split into two columns |
| Street + city + state combined | `OwnerAddress` | Split into three columns |
| Inconsistent flag values (`Y`/`N` vs `Yes`/`No`) | `SoldAsVacant` | Standardize to `Yes`/`No` |
| Duplicate sale records | (whole row) | Remove with `ROW_NUMBER()` |
| Redundant columns after splitting | multiple | Drop |

---

## Process — the cleaning

All cleaning logic lives in [`sql/02_data_cleaning.sql`](sql/02_data_cleaning.sql), commented step by step. Highlights:

1. **Standardized the sale date** — converted free-text dates to a consistent `DATE` type.
2. **Populated missing addresses** — a `ParcelID` always maps to one address, so blank addresses were filled from another row sharing the same `ParcelID` via a self-join and `ISNULL`. (~29 rows recovered.)
3. **Split `PropertyAddress`** into street and city using `SUBSTRING` + `CHARINDEX`.
4. **Split `OwnerAddress`** into street, city, and state using `PARSENAME` on a comma→period `REPLACE` — cleaner than nested substrings for three parts.
5. **Standardized `SoldAsVacant`** — collapsed `Y`/`N` into `Yes`/`No` with a `CASE` statement.
6. **Removed duplicates** — flagged identical sales (same parcel, address, price, date, legal reference) with `ROW_NUMBER()` inside a CTE, then deleted the extras.
7. **Dropped redundant columns** left over after splitting.

---

## Share — the outcome

The result is a clean, consistent, analysis-ready table: valid dates, no missing addresses, address components in their own filterable columns, standardized flags, and no duplicate sales.

**Next step (Analyze):** exploratory analysis on the cleaned data — sale price trends by city and year, vacant-land patterns, and price distribution — in `sql/03_exploratory_analysis.sql`.

---

## Repository structure

```
nashville-housing-data-cleaning/
├── data/
│   └── Nashville Housing Data for Data Cleaning.xlsx   # raw source
├── sql/
│   ├── 01_create_table_and_import.sql                  # schema + load
│   └── 02_data_cleaning.sql                            # cleaning pipeline
└── README.md
```

## How to reproduce

1. Run SQL Server (e.g. via Docker) and connect.
2. Convert the `.xlsx` to CSV and run `sql/01_create_table_and_import.sql` to build the staging table and load the data.
3. Run `sql/02_data_cleaning.sql` top to bottom against the freshly imported table.

## Skills demonstrated

`JOIN` (self-join) · `ISNULL` / `COALESCE` · `SUBSTRING` / `CHARINDEX` · `PARSENAME` / `REPLACE` · `CASE` · window functions (`ROW_NUMBER`) · CTEs · DDL (`ALTER TABLE`) · DML (`UPDATE`, `DELETE`) · bulk data loading.