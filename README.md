# Nashville Housing — SQL Data Cleaning

Transforming a messy ~56,000-row Nashville housing sales export into a clean, analysis-ready table in **Microsoft SQL Server**.

This project is deliberately scoped to the **data-cleaning stage** of the analytics workflow and is structured around the way a data task is actually handled in a workplace — **Ask → Prepare → Process** — so the reasoning behind each decision is visible, not just the final SQL.

---

## Ask — the objective

> *"Before anyone can analyze Nashville property sales, the raw export has to be made trustworthy. It has inconsistent date formats, missing property addresses, address fields that jam street, city, and state into a single column (so they can't be filtered or grouped), inconsistent categorical values, and duplicate sale records. Make it analysis-ready."*

**Success criteria:** a table with valid typed dates, no missing addresses, atomic address columns, standardized flags, and zero duplicate sales — something an analyst or BI tool could query with confidence.

---

## Prepare — the data & environment

| | |
|---|---|
| **Dataset** | Nashville housing sales export — `data/Nashville Housing Data for Data Cleaning.xlsx`, ~56,477 rows |
| **Database** | Microsoft SQL Server 2022 (Docker, macOS) |
| **Client** | VS Code with the SQL Server (mssql) extension |
| **Scripts** | `sql/01_create_table_and_import.sql`, `sql/02_data_cleaning.sql` |

**Loading strategy — a deliberate decision.** Letting the importer infer column types mangled the schema (misread dates, numerics coerced inconsistently). Instead, I created a staging table with every column typed as `NVARCHAR` and bulk-loaded into it, guaranteeing a lossless import. Correct types are then derived intentionally during cleaning, rather than being guessed at load time.

**Data-quality issues identified up front:**

| Issue | Column(s) | Approach |
|---|---|---|
| Dates stored as free text | `SaleDate` | Convert to a proper `DATE` |
| Missing property addresses | `PropertyAddress` | Recover via self-join on `ParcelID` |
| Street + city combined | `PropertyAddress` | Split into two atomic columns |
| Street + city + state combined | `OwnerAddress` | Split into three atomic columns |
| Inconsistent flags (`Y`/`N` vs `Yes`/`No`) | `SoldAsVacant` | Standardize to `Yes`/`No` |
| Duplicate sale records | whole row | Remove via `ROW_NUMBER()` + CTE |
| Redundant columns post-split | multiple | Drop |

---

## Process — the cleaning

Full commented logic in [`sql/02_data_cleaning.sql`](sql/02_data_cleaning.sql). Each step previews the change before applying it.

1. **Standardize the sale date** — convert free-text dates to a consistent `DATE` type.
2. **Recover missing addresses** — a `ParcelID` always maps to one property, so blank addresses are filled from another row sharing that `ParcelID` using a **self-join** and `ISNULL`.
3. **Split `PropertyAddress`** into street and city with `SUBSTRING` + `CHARINDEX`.
4. **Split `OwnerAddress`** into street, city, and state with `PARSENAME` over a comma→period `REPLACE` — far cleaner than nested substrings for three parts.
5. **Standardize `SoldAsVacant`** — collapse `Y`/`N` into `Yes`/`No` with a `CASE` expression.
6. **Remove duplicates** — flag identical sales (same parcel, address, price, date, legal reference) with `ROW_NUMBER()` inside a **CTE**, then delete the extras.
7. **Drop redundant columns** left behind after splitting.

---

## Result

A clean, consistent, de-duplicated table: valid dates, no missing addresses, atomic address components, standardized flags, and no duplicate sales. This table is the reliable foundation any downstream analysis or BI tool would build on.

---

## Repository structure

\`\`\`
nashville-housing-data-cleaning/
├── data/
│   └── Nashville Housing Data for Data Cleaning.xlsx   # raw source
├── sql/
│   ├── 01_create_table_and_import.sql                  # staging schema + bulk load
│   └── 02_data_cleaning.sql                            # 7-step cleaning pipeline
└── README.md
\`\`\`

## How to reproduce

1. Run SQL Server (e.g. via Docker) and connect from your SQL client.
2. Convert the `.xlsx` to CSV, then run `sql/01_create_table_and_import.sql` to build the staging table and bulk-load the data.
3. Run `sql/02_data_cleaning.sql` top to bottom against the freshly imported table.

## Skills demonstrated

`JOIN` (self-join) · `ISNULL` / `COALESCE` · `SUBSTRING` / `CHARINDEX` · `PARSENAME` / `REPLACE` · `CASE` · window functions (`ROW_NUMBER`) · CTEs · DDL (`ALTER TABLE`) · DML (`UPDATE` / `DELETE`) · bulk data loading · schema design decisions