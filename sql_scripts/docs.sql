COMMENT ON VIEW v_data_mart IS
'Detail-level sales mart for historical analysis.
- All attributes reflect state at time of transaction (SCD Type 2 compliant).
- Use promocode_is_used (boolean) instead of checking NULLs.
- tariff_version / promocode_version are 1-based version numbers per business key (tariff_name / promocode_code).';