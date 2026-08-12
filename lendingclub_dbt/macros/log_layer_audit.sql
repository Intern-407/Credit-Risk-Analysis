{% macro log_layer_audit(layer, model_relation) %}
  {% if execute %}
    insert into LENDING_CLUB.AUDIT.PIPELINE_AUDIT_LOG
      (layer, table_name, source_file, rows_loaded, rows_rejected, status, started_at, completed_at, duration_seconds)
    select
      '{{ layer }}',
      '{{ model_relation }}',
      null,
      (select count(*) from {{ model_relation }}),
      0,
      'SUCCESS',
      current_timestamp(),
      current_timestamp(),
      null
  {% endif %}
{% endmacro %}