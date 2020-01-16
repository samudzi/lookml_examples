view: order_patterns {
  derived_table: {
    sql: SELECT Row_number()
         OVER(
           ORDER BY ordered) AS row_number,
       *
FROM   (SELECT order_items.user_id                          AS user_id,
               order_items.id                               AS order_id,
               p.category                                   AS category,
               Min(order_items.created_at)
                 OVER(
                   partition BY order_items.user_id)        AS first_ordered_date,
               order_items.created_at                       AS ordered,
               Count(order_items.id)
                 OVER(
                   partition BY order_items.user_id)        AS lifetime_orders,
               Row_number()
                 OVER(
                   partition BY order_items.user_id
                   ORDER BY order_items.created_at)         AS order_sequence_number,
               Lead(order_items.created_at)
                 OVER(
                   partition BY order_items.user_id
                   ORDER BY order_items.created_at)         AS second_created_at,
               Datediff(day, Cast(order_items.created_at AS DATE
                             ),
               Cast(Lead(order_items.created_at)
               OVER(partition BY order_items.user_id
                 ORDER BY order_items.created_at) AS DATE)) AS repurchase_gap,
               Datediff(day, CURRENT_DATE, Cast(Min(order_items.created_at)
               OVER(
                 partition BY order_items.user_id) AS DATE)) AS days_since_first_order
        FROM   order_items
               JOIN inventory_items ii
                 ON order_items.inventory_item_id = ii.id
               JOIN products p
                 ON ii.product_id = p.id
                WHERE {% condition product_category %} p.category {% endcondition %}
        GROUP  BY 1,2,3,5)
 ;;
  }

  filter: product_category {
    suggest_dimension: category
  }

  measure: count {
    type: count
    drill_fields: [detail*]
  }

  dimension: row_number {
    hidden: yes
    primary_key: yes
    type: number
    sql: ${TABLE}.row_number ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension: category {
    type: string
    sql: ${TABLE}.category ;;
  }

  dimension_group: first_ordered_date {
    type: time
    sql: ${TABLE}.first_ordered_date ;;
  }

  dimension_group: ordered {
    type: time
    sql: ${TABLE}.ordered ;;
  }

  dimension: lifetime_orders {
    type: number
    sql: ${TABLE}.lifetime_orders ;;
  }

  dimension: lifetime_orders_tier {
    sql: ${lifetime_orders} ;;
    type: tier
    tiers: [1,2,3,4,5,6,7,8,9,10]
    style: integer
    drill_fields: [category,ordered_hour_of_day,product_category]
  }

  dimension: order_sequence_number {
    type: number
    sql: ${TABLE}.order_sequence_number ;;
  }

  dimension_group: second_created_at {
    type: time
    sql: ${TABLE}.second_created_at ;;
  }

  dimension: repurchase_gap {
    type: number
    sql: ${TABLE}.repurchase_gap ;;
  }

  dimension: repurchase_tier {
    type: tier
    tiers: [30,60,90,120,150,180]
    style: integer
    sql: ${repurchase_gap} ;;
  }

  dimension: days_since_first_order {
    type: number
    sql: ${TABLE}.days_since_first_order ;;
  }

  dimension: days_since_first_order_tier {
    type: tier
    tiers: [30,60,90,120,150,180]
    style: integer
    sql: ${days_since_first_order} ;;
  }

  dimension:  repurchase_made{
    type: yesno
    hidden: yes
    sql: ${repurchase_gap} IS NOT NULL ;;
  }

  measure: count_repurchases {
    description: "Count of unique users who have made more than 1 purchase"
    type: count_distinct
    drill_fields: [detail*]
    sql: ${user_id} ;;
    filters: {
      field: repurchase_made
      value: "yes"
    }
    filters: {
      field: order_sequence_number
      value: "2"
    }
  }
  measure: average_repurchase_gap {
    description: "The average time in days it takes for users to make a subsequent purchase"
    drill_fields: [detail*]
    type: average_distinct
    sql: ${repurchase_gap} ;;
    sql_distinct_key: ${order_id} ;;
    filters: {
      field: order_sequence_number
      value: "2"
    }

  }

### These dimensions will check if a user's 2nd purchase was within certain time intervals
  dimension: repurchase_30  {
    type:yesno
    sql:${repurchase_gap} <=30 AND  ${order_sequence_number}=2;;
    hidden:yes
    }

  dimension: repurchase_60  {
    type:yesno
    sql:${repurchase_gap} <=60 AND  ${order_sequence_number}=2;;
    hidden:yes
    }

  dimension: repurchase_90  {
    type:yesno
    sql:${repurchase_gap} <=90 AND  ${order_sequence_number}=2;;
    hidden:yes
    }

  dimension: repurchase_120 {
    type:yesno
    sql:${repurchase_gap} <=120 AND ${order_sequence_number}=2;;
    hidden:yes
    }

  dimension: repurchase_150 {
    type:yesno
    sql:${repurchase_gap} <=150 AND ${order_sequence_number}=2;;
    hidden:yes
    }

  dimension: repurchase_180 {
    type:yesno
    sql:${repurchase_gap} <=180 AND ${order_sequence_number}=2;;
    hidden:yes
    }

  ### Count of repurchases by users in N days since first purchase
  measure: count_repurchases_first_30_days {
    label: "1month"
    group_label: "Count Repurchases"
    type: count_distinct
    sql: ${user_id} ;;
    drill_fields: [detail*]
    filters: {
      field: repurchase_30
      value: "yes"
    }
  }
  measure: count_repurchases_first_60_days {
    label: "2months"
    group_label: "Count Repurchases"
    type: count_distinct
    sql: ${user_id} ;;
    drill_fields: [detail*]
    filters: {
      field: repurchase_60
      value: "yes"
    }
  }
  measure: count_repurchases_first_90_days {
    label: "3months"
    group_label: "Count Repurchases"
    type: count_distinct
    sql: ${user_id} ;;
    drill_fields: [detail*]
    filters: {
      field: repurchase_90
      value: "yes"
    }
  }
  measure: count_repurchases_first_120_days {
    label: "4months"
    group_label: "Count Repurchases"
    type: count_distinct
    sql: ${user_id} ;;
    drill_fields: [detail*]
    filters: {
      field: repurchase_120
      value: "yes"
    }
  }
  measure: count_repurchases_first_150_days {
    label: "5months"
    group_label: "Count Repurchases"
    type: count_distinct
    sql: ${user_id} ;;
    drill_fields: [detail*]
    filters: {
      field: repurchase_150
      value: "yes"
    }
  }
  measure: count_repurchases_first_180_days {
    label: "6months"
    group_label: "Count Repurchases"
    type: count_distinct
    sql: ${user_id} ;;
    drill_fields: [detail*]
    filters: {
      field: repurchase_180
      value: "yes"
    }
  }
  #### Repurchase rates

  measure: repurchase_rate {
    group_label: "Repurchase Rates"
    type: number
    drill_fields: [detail*]
    value_format_name: percent_1
    sql: 1.0*${count_repurchases}/nullif(${count_customers},0) ;;
  }
  measure: repurchase_rate_30 {
    label: "1month"
    group_label: "Repurchase Rates"
    type: number
    drill_fields: [detail*]
    value_format_name: percent_1
    sql: 1.0*${count_repurchases_first_30_days}/nullif(${count_customers},0) ;;
  }
  measure: repurchase_rate_60 {
    label: "2months"
    group_label: "Repurchase Rates"
    type: number
    drill_fields: [detail*]
    value_format_name: percent_1
    sql: 1.0*${count_repurchases_first_60_days}/nullif(${count_customers},0) ;;
  }
  measure: repurchase_rate_90 {
    label: "3months"
    group_label: "Repurchase Rates"
    type: number
    drill_fields: [detail*]
    value_format_name: percent_1
    sql: 1.0*${count_repurchases_first_90_days}/nullif(${count_customers},0) ;;
  }
  measure: repurchase_rate_120 {
    label: "4months"
    group_label: "Repurchase Rates"
    type: number
    drill_fields: [detail*]
    value_format_name: percent_1
    sql: 1.0*${count_repurchases_first_120_days}/nullif(${count_customers},0) ;;
  }
  measure: repurchase_rate_150 {
    label: "5months"
    group_label: "Repurchase Rates"
    type: number
    drill_fields: [detail*]
    value_format_name: percent_1
    sql: 1.0*${count_repurchases_first_150_days}/nullif(${count_customers},0) ;;
  }
  measure: repurchase_rate_180 {
    label: "6months"
    group_label: "Repurchase Rates"
    type: number
    drill_fields: [detail*]
    value_format_name: percent_1
    sql: 1.0*${count_repurchases_first_180_days}/nullif(${count_customers},0) ;;
  }
  measure: count_customers {
    drill_fields: [detail*]
    type: count_distinct
    sql: ${user_id} ;;
  }
  measure: count_orders {
    drill_fields: [detail*]
    type: count_distinct
    sql: ${order_id} ;;
  }
  measure: percent_of_customers {
    drill_fields: [detail*]
    type: percent_of_total
    sql: ${count_customers} ;;
  }

  measure: item_count_per_order {
    drill_fields: [detail*]
    type: number
    sql: ${count}/${count_orders} ;;
  }

  set: detail {
    fields: [
      row_number,
      user_id,
      order_id,
      category,
      first_ordered_date_time,
      ordered_time,
      lifetime_orders,
      order_sequence_number,
      second_created_at_time,
      repurchase_gap,
      days_since_first_order
    ]
  }
}
