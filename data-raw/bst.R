## code to prepare `bst` dataset goes here

xgb_counts_bot <- tfse::read_RDS("xgb-counts-model.rds")
xgb_props_bot <- tfse::read_RDS("xgb-props-model.rds")
source_types <- tfse::read_RDS("source_types.rds")

usethis::use_data(source_types, xgb_counts_bot, xgb_props_bot,
  overwrite = TRUE, internal = TRUE)
