class CategoriesController < ApplicationController
  include PackagesPagination

  helper_method :category, :packages

  def index
    @categories = SibrowserConfig::CATEGORIES
      .map { |c| [c, Package.by_category(c).count] }
      .sort_by(&:last)
      .reverse

    @page_title = t(:categories)
  end

  def show
    return packages_pagination(packages) if request.format.turbo_stream?

    package_count = packages.total_count

    tc = t(category, scope: :category_names, default: category)
    @page_title = t('title_category', category: tc)
    @page_description = t('description_category', category: tc, package_count:)

    set_meta_tags noindex: params['page'].present?

    @breadcrumbs = {
      parts: [
        [t(:categories), categories_path],
        tc
      ]
    }
  end

  def category
    params[:id]
  end

  def packages
    Package
      .visible_paged(params[:page])
      .by_category(category)
      .reorder_by_category(category)
      .order(created_at: :desc)
  end
end
