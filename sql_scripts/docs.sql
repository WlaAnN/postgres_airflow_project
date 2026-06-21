--=============================================================================
-- Слой Core & Base Data Mart (Детальный слой)
--=============================================================================

COMMENT ON VIEW v_data_mart IS
'Detail-level sales mart for historical analysis.
- Serving as the single source of truth (SSOT) for all downstream aggregate marts.
- All attributes reflect state at time of transaction (SCD Type 2 compliant).
- Use promocode_is_used (boolean) instead of checking NULLs to evaluate discount application.
- tariff_version / promocode_version are 1-based version numbers per business key (tariff_name / promocode_code) calculated via validation timeline.';

--=============================================================================
-- Слой Агрегированных Витрин (Downstream Analytical Marts)
--=============================================================================

COMMENT ON VIEW v_summary_mart IS
'High-level summary mart splitting global metrics by conversion source.
- Categorizes all financial activity into two strategic segments: "with_promo" and "no_promo".
- Contains transaction amounts, total net revenue, accumulated discounts, and segment share calculation.';

COMMENT ON VIEW v_by_day_mart IS
'Daily transaction performance and financial metrics mart.
- Grain: One row per calendar day (date_year, date_month_name, date_day).
- Includes absolute transaction volume, net revenue, average check, and promo usage penetration rate.';

COMMENT ON VIEW v_by_week_mart IS
'Weekly performance trend analysis mart.
- Grain: One row per ISO week within a calendar year.
- Designed for tracking short-term financial dynamics, velocity, and promotional campaigns efficiency.';

COMMENT ON VIEW v_by_month_mart IS
'Monthly financial reporting and macro-trend mart.
- Grain: One row per calendar month.
- Tracks sales volumes, net revenue, average check size, and percentage of promo-driven purchases.
- Sorted chronically by default using absolute timeline calendar projection.';

COMMENT ON VIEW v_by_quarter_mart IS
'Quarterly high-level management reporting mart.
- Grain: One row per fiscal quarter.
- Used for executive dashboards, seasonal fluctuations smoothing, and quarterly sales goals evaluation.';

COMMENT ON VIEW v_by_year_mart IS
'Strategic annual sales and company growth velocity mart.
- Grain: One row per calendar year.
- Contains historical year-over-year revenue generation, average pricing, and promo impact shifts.';

COMMENT ON VIEW v_by_tariff_mart IS
'Product-centric analytical mart evaluating tariff performance.
- Grain: One row per tariff name and specific tariff price/duration version (SCD Type 2 tracking).
- Implements DENSE_RANK processing to isolate and count strictly unique active users per historical version.
- Allows tracking how tariff pricing policy changes affected revenue and active user base acquisition.';

COMMENT ON VIEW v_by_promocode_mart IS
'Marketing-centric analytical mart evaluating discount campaigns.
- Grain: One row per promocode code and specific promo setup version.
- Strictly isolated to successful promo-driven transactions only (promocode_is_used IS TRUE).
- Tracks total generated net revenue, total burning discount costs, real discount percentage weight, total usage count, and absolute unique customer reach.';