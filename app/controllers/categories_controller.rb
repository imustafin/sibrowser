class CategoriesController < ApplicationController
  def index
    @categories = SibrowserConfig::CATEGORIES
      .map { |c| [c, Package.by_category(c).count] }
      .sort_by(&:last)
      .reverse

    @page_title = t(:categories)
  end

  def show
    @category = params[:id]

    @packages = Package
      .visible_paged(params[:page])
      .by_category(@category)
      .reorder_by_category(@category)

    @package_count = @packages.total_count

    @page_title = t('title_category', category: @category)
    @page_description = t('description_category', category: @category, package_count: @package_count)

    set_meta_tags noindex: params['page'].present?

    @breadcrumbs = {
      parts: [
        [t(:categories), categories_path],
        @category
      ]
    }
  end

end
