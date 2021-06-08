module ApplicationHelper
  TYPE_COLORS = {
    image: 'bg-red-500',
    text: 'bg-green-500',
    video: 'bg-yellow-500',
    voice: 'bg-blue-500',
    mixed: 'bg-black'
  }

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

    render partial: 'components/packages_table/sortable', locals: {
      title: title,
      column: column,
      direction: new_direction,
      icon: icon,
      q: params[:q],
      html_params: html_params
    }
  end

  def distribution(dist)
    render partial: 'components/distribution', locals: dist
  end

  def author_link(author, **kwargs)
    locale = request.path_parameters[:locale]
    params = { locale: locale, id: author }
    link_to author, author_path(params), **kwargs
  end
end
