explore: weather_period_over_period {
  fields: [ALL_FIELDS*,
    -weather_period_2.period_1,
    -weather_period_2.period_2,
    -weather_period_2.comparison_interval,
    -weather_period_2.intervals_into_period_1,
    -weather_period_2.intervals_into_period_2,
    -weather_period_2.periods]
  view_label: "Weather Period 1"
  from: bq_gsod
  join: weather_period_2{
    type: full_outer
    from: bq_gsod
    relationship: one_to_one
    sql_on: false ;;
  }
  sql_always_where:
  {% condition weather_period_over_period.period_1 %} ${weather_period_over_period.weather_raw} {% endcondition %}
  OR
  {% condition weather_period_over_period.period_2 %} ${weather_period_2.weather_raw} {% endcondition %} ;;
}


view: bq_gsod {
  sql_table_name: `bigquery-public-data.noaa_gsod.gsod*` ;;

  parameter: comparison_interval {
    view_label: "Period Over Period"
    type: unquoted
    allowed_value: {
      value: "Day"
    }
    allowed_value: {
      value: "Week"
    }
    allowed_value: {
      value: "Month"
    }
    allowed_value: {
      value: "Quarter"
    }
    allowed_value: {
      value: "Year"
    }
  }

  filter: period_1 {
    view_label: "Period Over Period"
    type: date
  }

  filter: period_2 {
    view_label: "Period Over Period"
    type: date
  }

  dimension: intervals_into_period_1 {
    hidden: yes
    view_label: "Period Over Period"
    type: number
    sql: DATE_DIFF(${weather_period_over_period.weather_date},
         CAST(TIMESTAMP(split(split("{% condition weather_period_over_period.period_1 %} ${weather_period_over_period.weather_raw} {% endcondition %}",">= (TIMESTAMP('")[ORDINAL(2)],"')) AND")[ORDINAL(1)]) as DATE),
         {% parameter comparison_interval %}) ;;
  }

  dimension: intervals_into_period_2 {
    hidden: yes
    view_label: "Period Over Period"
    type: number
    sql: DATE_DIFF(${weather_period_2.weather_date},
         CAST(TIMESTAMP(split(split("{% condition weather_period_over_period.period_2 %} ${weather_period_over_period.weather_raw} {% endcondition %}",">= (TIMESTAMP('")[ORDINAL(2)],"')) AND")[ORDINAL(1)]) as DATE),
         {% parameter comparison_interval %}) ;;
  }

  dimension: periods {
    view_label: "Period Over Period"
    label: "{% parameter comparison_interval %}s into Period"
    type: number
    sql: coalesce(${intervals_into_period_1},${intervals_into_period_2}) ;;
  }

  #Other dimensions and measures...
  
}
