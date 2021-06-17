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
