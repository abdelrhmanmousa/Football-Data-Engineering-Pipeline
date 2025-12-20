from dagster import Definitions, load_assets_from_modules

# We import the assets file from the SAME folder (.)
from . import assets
from .resources import dbt_resource

# This loads all functions decorated with @asset or @dbt_assets
all_assets = load_assets_from_modules([assets])

defs = Definitions(
    assets=all_assets,
    resources={
        "dbt": dbt_resource,
    },
)