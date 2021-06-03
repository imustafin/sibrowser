module PackagesHelper
  def sortable(title, column, html_params={})
    column = column.to_sym

    new_direction = (column == sort_column && sort_direction == :asc) ? :desc : :asc

    icon = case
           when column != sort_column
               'selector'
           when sort_direction == :asc
             'chevron-up'
           else
             'chevron-down'
           end

    render partial: 'sortable', locals: {
      title: title,
      column: column,
      direction: new_direction,
      icon: icon,
      q: params[:q],
      html_params: html_params
    }
  end

  def distribution(dist)
    render partial: 'distribution', locals: dist
  end

  def button_class(params = {})
    small = params[:type] == :small

    py = small ? 'py-1' : 'py-2'

    "border-4 border-transparent inline-block bg-purple-500 #{py} px-4 font-bold text-white hover:border-purple-600 "
  end
end
