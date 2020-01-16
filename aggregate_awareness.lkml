Below is a complex example using all of the concepts at once. Let's imagine we have user-level information and our measure is sensitive to whether or not it is grouped by user_id. We already have an existing daily summary of this information, but we want Looker to summarize by month. We also need a daily and monthly summarization at the user level. The end user should choose whether user_id is respected in the aggregation totals.

For this purpose, we could write code like the following:

view: event_facts_monthly {
 derived_table: {
 sql_trigger_value: select DATE_TRUNC('month',current_date) ;;
 distribution_style: all
 sortkeys: ["TIME"]
 sql: SELECT
 DATE_TRUNC('month',created_at) AS TIME
 ,COUNT(*) AS COUNT
 FROM
 PUBLIC.EVENTS
 WHERE
 1=1
 GROUP BY
 1
 ;;
 }
}

view: event_facts_user {
 derived_table: {
 sql_trigger_value: select DATE_TRUNC('day',current_date) ;;
 distribution_style: all
 sortkeys: ["TIME"]
 sql: SELECT
 DATE_TRUNC('day',created_at) AS TIME
 ,user_id
 ,COUNT(*) AS COUNT
 FROM
 PUBLIC.EVENTS
 WHERE
 1=1
 GROUP BY
 1,2
 ;;
 }
}

view: event_facts_user_monthly {
 derived_table: {
 sql_trigger_value: select DATE_TRUNC('month',current_date) ;;
 distribution_style: all
 sortkeys: ["TIME"]
 sql: SELECT
 DATE_TRUNC('month',created_at) AS TIME
 ,user_id
 ,COUNT(*) AS COUNT
 FROM
 PUBLIC.EVENTS
 WHERE
 1=1
 GROUP BY
 1,2
 ;;
 }
}


view: events {
 derived_table: {
 sql:
 -- This notation is just to make create a more readable user_input variable for casing off the value the user put in
 {% assign user_input = events.calc_method_value_pass_through._sql %}

SELECT * FROM
 -- Select the appropriate table for user_level calculation
 {% if user_input contains 'User Level' %}
 -- Select the appropriate table based on time grain chosen
 {% if time_date._in_query or time_week._in_query %}
 ${event_facts_user.SQL_TABLE_NAME}
 {% else %}
 ${event_facts_user_monthly.SQL_TABLE_NAME}
 {% endif %}
 {% else %}
 -- Select the appropriate table based on time grain chosen
 {% if time_date._in_query or time_week._in_query %}
 schema.event_facts -- For example if this table already existed in another schema and was not a PDT assigned in Looker
 {% else %}
 ${event_facts_monthly.SQL_TABLE_NAME}
 {% endif %}
 {% endif %}
 ;;
 }

dimension_group: time {
 type: time
 timeframes: [date, week, month, year]
 sql: ${TABLE}.TIME ;;
 }

filter: calc_method {
 type: string
 suggestions: [
 "User Level",
 "Global"
 ]
 }

dimension: calc_method_value_pass_through {
 hidden: yes
 type: string
 sql: {% parameter calc_method %} ;;
 }

measure: count {
 type: sum
 sql: ${TABLE}.count ;;
 drill_fields: [time_date,count]
 }

}
