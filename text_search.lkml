dimension: search_string {
    type: string
    sql:
      {% assign full_string = "" %}
      {% if prompt_reason_for_study._parameter_value <> "'NO_SEARCH_CRITERIA_SPECIFIED'" %}
        {% assign full_string = prompt_reason_for_study._parameter_value | remove: "'" | append: " within reason_for_study" %}
      {% endif %}
      {% if prompt_clinical_info._parameter_value <> "'NO_SEARCH_CRITERIA_SPECIFIED'" %}
        {% if full_string <> '' %}
          {% assign full_string = full_string | append: " AND "  %}
        {% endif %}
        {% assign full_string = full_string | append: prompt_clinical_info._parameter_value | remove: "'" | append: " within clinical_info" %}
      {% endif %}
      {% if prompt_study_comments._parameter_value <> "'NO_SEARCH_CRITERIA_SPECIFIED'" %}
        {% if full_string <> '' %}
          {% assign full_string = full_string | append: " AND "  %}
        {% endif %}
        {% assign full_string = full_string | append: prompt_study_comments._parameter_value | remove: "'" | append: " within study_comment" %}
      {% endif %}
      {% if prompt_report_text._parameter_value <> "'NO_SEARCH_CRITERIA_SPECIFIED'" %}
        {% if full_string <> '' %}
          {% assign full_string = full_string | append: " AND "  %}
        {% endif %}
        {% assign full_string = full_string | append: prompt_report_text._parameter_value | remove: "'" | append: " within report_text" %}
      {% endif %}
      {% if prompt_any._parameter_value <> "'NO_SEARCH_CRITERIA_SPECIFIED'" %}
        {% if full_string <> '' %}
          {% assign full_string = full_string | append: " AND "  %}
        {% endif %}
        {% assign full_string = full_string | append: prompt_any._parameter_value | remove: "'"  %}
      {% endif %}
      '{{ full_string }}'
    ;;
