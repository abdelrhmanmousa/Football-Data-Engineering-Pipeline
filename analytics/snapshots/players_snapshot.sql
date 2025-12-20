{% snapshot players_snapshot %}

{{
    config(
      target_schema='snapshots',
      unique_key='player_id',
      strategy='check',
      check_cols=['nationality', 'first_name', 'last_name'],
      invalidate_hard_deletes=True
    )
}}

select * from {{ ref('stg_players') }}

{% endsnapshot %}