##Text highlighting on search

dimension: snippet {
   type: string
   sql:
     CAST(CTX_DOC.SNIPPET('DWH_AGILITY.idx_report_text',
     ${requested_procedure_bk}
     , ${search_string}, '[',']') AS VARCHAR(4000))
   ;;
 html:
 {% assign searchkey = "" %}
 {% assign searchkey = searchkey | append: prompt_report_text._parameter_value | remove: "'" | append: "" %}
 {% assign words = value | split: searchkey %}
     {{words[0]}}<b>{{searchkey}}</b>{{words[1]}}
  ;;
 }
