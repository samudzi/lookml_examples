###Subtotals


#The Model
explore: order_items {
  # Join other views as usual.
  join: products {
    sql_on: ${order_items.product_id} = ${products.id} ;;
    relationship: many_to_one
  }
 #Join the subtotaling view using a cross join.
  join: subtotal_over {
    type: cross
    relationship: one_to_many
  }
#Optionally, additional levels of nested subtotals can be enabled as follows
  join: subtotal_over_level2 {
    from: subtotal_over
    type: cross
    relationship: one_to_many
    #when adding a level of nested subtotals, need to add this sql_where to exclude the generated row which would subtotal over the higher level, but not over this lower level.
    sql_where: not (${subtotal_over.row_type_description}='SUBTOTAL' and not ${subtotal_over_level2.row_type_description}='SUBTOTAL') ;;
  }

#While you can pivot subtotal_over dimensions as you'd expect, if you want to see subtotals for BOTH regular dimensions and pivot dimensions simultaneously, add another layer of subtotaling as follows
  join: subtotal_over_for_pivot {
    from: subtotal_over
    type: cross
    relationship: one_to_many
  }
}

#The Subtotals View

view: subtotal_over {
  sql_table_name: (select '' as row_type union select null as row_type) ;; #This sql table name is used to create a duplicate copy of the data. When rowType is null, fields from this view will resolve to 'SUBTOTAL'

  #used in sql parameters below to re-assign values to 'SUBTOTAL' on subtotal rows
  dimension: row_type_checker {
    hidden:yes
    sql: ${TABLE}.row_type ;;
  }
  # used for readability in sql_where of nested subtotal join
  dimension: row_type_description {
    hidden:yes
    sql:coalesce(${TABLE}.row_type,'SUBTOTAL');;
  }

#######################################
### Example String Based Dimensions ###
  dimension: product_name {
    order_by_field: product_order
    # For subtotal rows: show 'SUBTOTAL'.  For nulls, show '∅' (supports intuitive sorting).  Otherwise use raw base table field's data. Note, concatenation with '${row_type_checker}' is used to concisely force subtotal rows to evaluate to null, which is then converted to 'SUBTOTAL'
    sql: coalesce(cast(coalesce(cast(${products.name} as varchar),'∅')||${row_type_checker} as varchar),'SUBTOTAL');;
  }
  dimension: product_order {
    hidden: yes
    #For order by fields, use a similar calculation, but use values that correctly put nulls at min and subtotals at max of sort order positioning
    sql: coalesce(cast(coalesce(cast(${products.name} as varchar),'          ')||${row_type_checker} as varchar),'ZZZZZZZZZZ');;
  }

#######################################
### Example Number Based Dimensions ###
  dimension: sale_price {
    order_by_field: sale_price_order
    sql: coalesce(cast(coalesce(cast(${order_items.sale_price} as varchar),'∅')||${row_type_checker} as varchar),'SUBTOTAL');;
  }
  dimension: sale_price_order {
    hidden: yes
    type: number
    sql: coalesce(cast(coalesce(cast(${order_items.sale_price} as float),-9999999999)||${row_type_checker} as float),9999999999);;
  }

#####################################
### Example Tier Based Dimensions ###
  dimension: sale_price_tier {
    order_by_field: sale_price_tier_order
    sql: coalesce(cast(coalesce(cast(${order_items.sale_price_tier} as varchar),'∅')||${row_type_checker} as varchar),'SUBTOTAL');;
  }
  # Tier based dimensions work similarly to string fields, but need to leverage Looker's built in Tier Sorting dimension by adding '__sort_' to the base field name in the order by field
  dimension: sale_price_tier_order {
    hidden:yes
    sql: coalesce(cast(coalesce(cast(${order_items.sale_price_tier__sort_} as varchar),'          ')||${row_type_checker} as varchar),'ZZZZZZZZZZ');;
  }

#####################################
### Example Date Based Dimensions ###
  # Note that you can use one dimension group for order_by_field, but must create each timeframe separately.
  # Timeframes that represent contiguous datetime ranges, like day, week, month, quarter, year, etc, work as shown here.  Conversely, for timeframes like month_num or day_of_week, you can use the string pattern or numeric pattern from above as appropriate.
  dimension: created_year {
    order_by_field: created_order_year
    sql: coalesce(cast(coalesce(cast(${order_items.created_year} as varchar),'∅')||${row_type_checker} as varchar),'SUBTOTAL');;
  }
  dimension: created_quarter {
    order_by_field: created_order_quarter
    sql: coalesce(cast(coalesce(cast(${order_items.created_quarter} as varchar),'∅')||${row_type_checker} as varchar),'SUBTOTAL');;
  }
  dimension: created_date {
    order_by_field: created_order_date
    sql: coalesce(cast(coalesce(cast(${order_items.created_date} as varchar),'∅')||${row_type_checker} as varchar),'SUBTOTAL');;
  }
  dimension_group: created_order {
    hidden: yes
    type: time
    timeframes: [raw,minute,hour,date,week,month,quarter,year]
    #for date fields, use _raw version of the base field, and use datetime datatype and defaults in the order by field's sql.  1900-01-02 and 9999-12-30 used to remain as valid dates in case of any timezone conversion.
    sql:  coalesce(cast(coalesce(cast(${order_items.created_raw} as datetime),'1900-01-02')||${row_type_checker} as datetime),'9999-12-30');;
  }
}
