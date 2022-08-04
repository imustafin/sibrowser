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

  def admin?
    session[:admin]
  end

  def first_index(kaminari)
  end

  def package_description(package, for_html=false)
    if package.post_text.present?
      text = package.post_text
      text = simple_format(text) if for_html

      text.squish
    elsif package.question_distribution.present?
      total = package.question_distribution[:total]
      type_strings = package.question_distribution[:types].map do |type, count|
        t(type) + ': ' + number_to_percentage(count.to_f / total * 100, precision: 0)
      end

      type_strings.join(', ')
    end
  end
end
