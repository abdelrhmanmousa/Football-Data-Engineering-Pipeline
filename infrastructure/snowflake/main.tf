resource "snowflake_database" "db" {
  name = "FOOTBALL_DB"
}

resource "snowflake_schema" "raw" {
  database = snowflake_database.db.name
  name     = "RAW"
}

resource "snowflake_schema" "analytics" {
  database = snowflake_database.db.name
  name     = "ANALYTICS"
}

# 1. File Format (JSON)
resource "snowflake_file_format" "json" {
  database    = snowflake_database.db.name
  schema      = snowflake_schema.raw.name
  name        = "JSON_FORMAT"
  format_type = "JSON"
}

# 2. Storage Integration (The Security Link)
resource "snowflake_storage_integration" "s3_int" {
  name                      = "FOOTBALL_S3_INT"
  type                      = "EXTERNAL_STAGE"
  enabled                   = true
  storage_provider          = "S3"
  storage_aws_role_arn      = var.storage_aws_role_arn
  storage_allowed_locations = ["s3://${var.s3_bucket_name}/"]
}

# 3. The Stage (The Pointer)
resource "snowflake_stage" "s3_stage" {
  name                = "FOOTBALL_S3_STAGE"
  database            = snowflake_database.db.name
  schema              = snowflake_schema.raw.name
  url                 = "s3://${var.s3_bucket_name}/raw/"
  storage_integration = snowflake_storage_integration.s3_int.name
  file_format         = "FORMAT_NAME = \"${snowflake_database.db.name}\".\"${snowflake_schema.raw.name}\".\"${snowflake_file_format.json.name}\""
}

# 4. External Tables (Map S3 files to SQL Tables)

# FIXTURES
resource "snowflake_external_table" "raw_fixtures" {
  database = snowflake_database.db.name
  schema   = snowflake_schema.raw.name
  name     = "RAW_FIXTURES"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Parses 'ingestion_date=2025-01-01' from Hive path
    as   = "to_date(split_part(metadata$filename, '=', 3), 'YYYY-MM-DD')"
  }
  column {
    name = "json_data"
    type = "VARIANT"
    as   = "$1"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  # Pointing to the 'fixtures' folder inside the stage
  location     = "@${snowflake_database.db.name}.${snowflake_schema.raw.name}.${snowflake_stage.s3_stage.name}/fixtures/"
  auto_refresh = false 
}

# PLAYERS
resource "snowflake_external_table" "raw_players" {
  database = snowflake_database.db.name
  schema   = snowflake_schema.raw.name
  name     = "RAW_PLAYERS"
  column {
    name = "ingestion_date"
    type = "DATE"
    as   = "to_date(split_part(metadata$filename, '=', 3), 'YYYY-MM-DD')"
  }
  column {
    name = "json_data"
    type = "VARIANT"
    as   = "$1"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.db.name}.${snowflake_schema.raw.name}.${snowflake_stage.s3_stage.name}/players/"
  auto_refresh = false
}

# STANDINGS
resource "snowflake_external_table" "raw_standings" {
  database = snowflake_database.db.name
  schema   = snowflake_schema.raw.name
  name     = "RAW_STANDINGS"
  column {
    name = "ingestion_date"
    type = "DATE"
    as   = "to_date(split_part(metadata$filename, '=', 3), 'YYYY-MM-DD')"
  }
  column {
    name = "json_data"
    type = "VARIANT"
    as   = "$1"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.db.name}.${snowflake_schema.raw.name}.${snowflake_stage.s3_stage.name}/standings/"
  auto_refresh = false
}