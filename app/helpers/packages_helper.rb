module PackagesHelper
  def sortable(title, column)
    column = column.to_sym

    new_direction = (column == sort_column && sort_direction == :asc) ? :desc : :asc

    icon = case
           when column != sort_column
               'selector'
           when sort_direction == :asc
             'chevron-down'
           else
             'chevron-up'
           end

    render partial: 'sortable', locals: {
      title: title,
      column: column,
      direction: new_direction,
      icon: icon
    }
  end
end
