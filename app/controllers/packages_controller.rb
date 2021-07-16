class PackagesController < ApplicationController
  include PackagesTable

  def index
    ps = table_packages

    # Do this after order(sort_column) to first order by sort_column, then by search rank
    ps = ps.search_freetext(params[:q]) if params[:q].present?

    @packages = ps

    if params['page']
      @page_title = t('title_packages_page', page: params['page'])
    end

    set_meta_tags noindex: any_sorting? || params[:q].present? || params['page'].present?
  end

  def show
    @package = Package.find(params[:id])

    @page_title = t(
      'title_package',
      name: @package.name,
      authors: @package.authors.present? ? " (#{@package.authors.join(', ')})" : ''
    )

    @page_description = package_description(@package)

    if helpers.admin?
      @cats = SibrowserConfig::CATEGORIES
    end
  end

  def toggle_cat
    return head(:forbidden) unless helpers.admin?

    p = Package.find(params[:package_id])

    cat = params[:cat]
    cur = p.manual_categories || []
    if cur.include?(cat)
      cur -= [cat]
    else
      cur += [cat]
    end

    p.manual_categories = cur

    p.save!

    redirect_to action: :show, id: params[:package_id]
  end

  private

  def package_description(package)
    ans = ''

    if package.question_distribution.present?
      total = package.question_distribution[:total]
      type_strings = package.question_distribution[:types].map do |type, count|
        t(type) + ': ' + helpers.number_to_percentage(count.to_f / total * 100, precision: 0)
      end

      ans += type_strings.join(', ')
    end

    if package.post_text.present?
      ans += '. ' + package.post_text.squish
    end

    ans
  end
end
