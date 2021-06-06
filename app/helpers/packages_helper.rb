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

  def package_description(package)
    ans = ''

    if package.question_distribution.present?
      total = package.question_distribution[:total]
      type_strings = package.question_distribution[:types].map do |type, count|
        t(type) + ': ' + number_to_percentage(count.to_f / total * 100, precision: 0)
      end

      ans += type_strings.join(', ')
    end

    if package.post_text.present?
      ans += '. ' + package.post_text.squish
    end

    ans
  end
end
