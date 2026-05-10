# Data Dictionary — Supermarket Sales Analytics

## Source Files (Kaggle)

### annex1.csv → RAW_PRODUCTS / DIM_PRODUCT
| Column | Type | Description |
|--------|------|-------------|
| Item Code | INTEGER | Unique barcode-style product identifier |
| Item Name | VARCHAR | Product display name (Chinese transliterated to English) |
| Category Code | INTEGER | Numeric category identifier |
| Category Name | VARCHAR | One of 6 fresh produce categories (see below) |

**Categories:**
| Name | Slug | Description |
|------|------|-------------|
| Flower/Leaf Vegetables | leafy | Leafy greens, lettuce, bok choy, etc. |
| Cabbage | cabbage | Chinese cabbages, napa, etc. |
| Aquatic Tuberous Vegetables | aquatic | Lotus root, water chestnuts, taro |
| Solanum | solanum | Tomatoes, eggplant, nightshade family |
| Capsicum | capsicum | Bell peppers, chili peppers |
| Edible Mushroom | mushroom | Shiitake, oyster, enoki, etc. |

---

### annex2.csv → RAW_SALES / FACT_SALES
| Column | Type | Description |
|--------|------|-------------|
| Date | DATE (YYYY-MM-DD) | Transaction date |
| Time | TIME | Transaction timestamp (to millisecond) |
| Item Code | INTEGER | FK → DIM_PRODUCT.item_code |
| Quantity Sold (kilo) | FLOAT | Weight sold in kilograms |
| Unit Selling Price (RMB/kg) | FLOAT | Retail price in Chinese yuan per kg |
| Sale or Return | VARCHAR | `'sale'` or `'return'` |
| Discount (Yes/No) | VARCHAR | Whether a promotional discount was applied |

---

### annex3.csv → RAW_WHOLESALE_PRICES
| Column | Type | Description |
|--------|------|-------------|
| Date | DATE | Price date |
| Item Code | INTEGER | FK → DIM_PRODUCT.item_code |
| Wholesale Price (RMB/kg) | FLOAT | Daily procurement/cost price in yuan per kg |

> **Note**: Not every product has a wholesale price for every date. LEFT JOINs are used to handle this gracefully.

---

### annex4.csv → RAW_LOSS_RATES / DIM_PRODUCT.loss_rate_pct
| Column | Type | Description |
|--------|------|-------------|
| Item Code | INTEGER | FK → DIM_PRODUCT.item_code |
| Item Name | VARCHAR | Product name (for reference) |
| Loss Rate (%) | FLOAT | Expected % of purchased goods lost to spoilage/trim |

---

## Derived / Calculated Fields

### FACT_SALES

| Field | Formula | Description |
|-------|---------|-------------|
| `gross_revenue_rmb` | `quantity_sold_kg × unit_price_rmb_kg` | Revenue before accounting for loss |
| `txn_sign` | `+1` (sale) / `-1` (return) | Multiplier for net volume calculations |
| `margin_per_kg` | `selling_price − wholesale_price` | Absolute margin per kg |
| `margin_pct` | `(sell − wholesale) / wholesale × 100` | % margin over cost |
| `retention_factor` | `1 − (loss_rate_pct / 100)` | From DIM_PRODUCT |
| `effective_qty_kg` | `quantity_sold_kg × retention_factor` | Loss-adjusted quantity |
| `net_revenue_rmb` | `effective_qty_kg × unit_price_rmb_kg` | Loss-adjusted revenue |

### DIM_DATE

| Field | Description |
|-------|-------------|
| `date_key` | Surrogate key: `YYYYMMDD` integer |
| `fiscal_year` | Format `YYYY-YYYY`; fiscal year runs July–June |
| `fiscal_quarter` | FQ1 (Jul–Sep) through FQ4 (Apr–Jun) |
| `season` | Northern hemisphere: Winter / Spring / Summer / Autumn |
| `is_weekend` | TRUE for Saturday and Sunday |

---

## Notes on Data Quality

- **Date coverage**: 2020-07-01 to 2023-06-30 (exactly 3 fiscal years)
- **Wholesale price coverage**: ~6.4% of product-date combinations have a wholesale price; missing values result in NULL margins
- **Returns**: ~2% of transactions are returns (negative in aggregations using `txn_sign`)
- **Loss rates**: All 251 products have an associated loss rate
- **Currency**: All monetary values in RMB (Chinese yuan, ¥)
