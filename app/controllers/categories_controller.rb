class CategoriesController < ApplicationController
  include PackagesTable

  def index
    @categories = SibrowserConfig::CATEGORIES
      .map { |c| [c, Package.by_category(c).count] }
      .sort_by(&:last)
      .reverse

    @page_title = t(:categories)
  end

  def show
    @category = params[:id]

    ps = table_packages

    ps = table_packages.by_category(@category)

    ps = ps.reorder_by_category(@category)

    @package_count = Package.by_category(@category).count

    @packages = ps

    @page_title = t('title_category', category: @category)
    @page_description = t('description_category', category: @category, package_count: @package_count)
  end

end
