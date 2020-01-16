##Dynamically choose timeframe with parameter without having to manually select timeframe

dimension: dynamic_date {
 label: "Dynamic Date"
 type: string
 sql:
 CASE
 WHEN datediff({% date_end created_date %}, {% date_start created_date %}) < 30 THEN ${created_date}
 WHEN datediff({% date_end created_date %}, {% date_start created_date %}) > 365 THEN ${created_year}
 WHEN datediff({% date_end created_date %}, {% date_start created_date %}) > 90 THEN ${created_month}
 WHEN datediff({% date_end created_date %}, {% date_start created_date %}) > 30 THEN ${created_week}
 ELSE ${created_month}
 END ;;
 }
