resource "snowflake_database" "football_db" {
  name = "FOOTBALL_LEAGUES_DB"
}

resource "snowflake_schema" "raw_schema" {
  database = snowflake_database.football_db.name
  name     = "RAW"
}

resource "snowflake_schema" "analytics_schema" {
  database = snowflake_database.football_db.name
  name     = "ANALYTICS"
}

resource "snowflake_file_format" "json_format" {
  database    = snowflake_database.football_db.name
  schema      = snowflake_schema.raw_schema.name
  name        = "JSON_FORMAT"
  format_type = "JSON"
}

resource "snowflake_storage_integration" "s3_int" {
  name                      = "FOOTBALL_LEAGUES_S3_INT"
  type                      = "EXTERNAL_STAGE"
  enabled                   = true
  storage_provider          = "S3"
  storage_aws_role_arn      = var.aws_role_arn
  storage_allowed_locations = ["s3://${var.s3_bucket_name}/"]
}


resource "snowflake_stage" "s3_stage" {
  name                = "FOOTBALL_LEAGUES_STAGE"
  database            = snowflake_database.football_db.name
  schema              = snowflake_schema.raw_schema.name
  url                 = "s3://${var.s3_bucket_name}/raw/"
  storage_integration = snowflake_storage_integration.s3_int.name

  file_format = "FORMAT_NAME = \"${snowflake_database.football_db.name}\".\"${snowflake_schema.raw_schema.name}\".\"${snowflake_file_format.json_format.name}\""
}


# External Tables

resource "snowflake_external_table" "raw_players" {
  database = snowflake_database.football_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_PLAYERS"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Extract YYYY-MM-DD from "path/ingestion_date=2024-01-01/file.json"
    as = "to_date(split_part(split_part(metadata$filename, 'ingestion_date=', 2), '/', 1), 'YYYY-MM-DD')"
  }
  column {
    name = "results"
    type = "VARIANT"
    as   = "$1:results"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.football_db.name}.${snowflake_schema.raw_schema.name}.${snowflake_stage.s3_stage.name}/players/"
  auto_refresh = false
}

resource "snowflake_external_table" "raw_standings" {
  database = snowflake_database.football_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_STANDINGS"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Extract YYYY-MM-DD from "path/ingestion_date=2024-01-01/file.json"
    as = "to_date(split_part(split_part(metadata$filename, 'ingestion_date=', 2), '/', 1), 'YYYY-MM-DD')"
  }
  column {
    name = "results"
    type = "VARIANT"
    as   = "$1:results"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.football_db.name}.${snowflake_schema.raw_schema.name}.${snowflake_stage.s3_stage.name}/standings/"
  auto_refresh = false
}

resource "snowflake_external_table" "raw_fixtures" {
  database = snowflake_database.football_db.name
  schema   = snowflake_schema.raw_schema.name
  name     = "RAW_FIXTURES"
  column {
    name = "ingestion_date"
    type = "DATE"
    # Extract YYYY-MM-DD from "path/ingestion_date=2024-01-01/file.json"
    as = "to_date(split_part(split_part(metadata$filename, 'ingestion_date=', 2), '/', 1), 'YYYY-MM-DD')"
  }
  column {
    name = "results"
    type = "VARIANT"
    as   = "$1:results"
  }
  partition_by = ["ingestion_date"]
  file_format  = "TYPE = JSON"
  location     = "@${snowflake_database.football_db.name}.${snowflake_schema.raw_schema.name}.${snowflake_stage.s3_stage.name}/fixtures/"
  auto_refresh = false
}
