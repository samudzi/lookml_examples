##add to model

join: invited_users {
    from: invited_users
    type: left_outer
    relationship: one_to_one
    sql_on: ${invited_users.fullvisitorid}=${ga_sessions.fullVisitorId};;
# The following toggle allows you to change the join type from Left to inner.
# Setting  ${invited_users.fullvisitorid} to not null makes the join an inner join.
# Setting 1=1 removes the filter and changes the join type to left outer.
      sql_where: {% if invited_users.left_join._parameter_value == "'Yes'" %}
                            1=1
                        {% else %}
          ${invited_users.fullvisitorid} is not null
                        {% endif %};;
    }
