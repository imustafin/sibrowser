class CategoriesController < ApplicationController
  include PackagesTable

  def index
    @categories = SibrowserConfig::CATEGORIES
      .map { |c| [c, category_count(c)] }
      .sort_by(&:last)
      .reverse

    @page_title = t(:categories)
  end

  def show
    @category = params[:id]

    ps = table_packages

    ps = table_packages.select { |p| p.categories.include?(@category) }

    def ps.total_pages
      1
    end

    def ps.current_page
      1
    end

    def ps.limit_value
      10
    end

    @package_count = category_count(@category)

    @packages = ps

    @page_title = t('title_category', category: @category)
    @page_description = t('description_category', category: @category, package_count: @package_count)
  end

  private

  def category_count(category)
    Package.select { |p| p.categories.include?(category) }.count
  end
end
