import os
from dagster import file_relative_path
from dagster_dbt import DbtCliResource

# Point to your analytics folder
DBT_PROJECT_DIR = file_relative_path(__file__, "../../../analytics")

# Create the dbt resource
dbt_resource = DbtCliResource(
    project_dir=DBT_PROJECT_DIR,
)