class CategoriesController < ApplicationController
  include PackagesPagination

  helper_method :category, :packages, :show_title

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
    @page_title = show_title
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
    p = Package
      .visible
      .by_category(category)

    if sort_column == :relevance
      p = p.order_by_category(category)
    else
      p = p.order(sort_column => :desc)
    end

    p
      .order(id: :desc)
      .page(params[:page]).per(5)
  end

  def supported_sort_columns
    %i[published_at download_count relevance]
  end

  def sort_column
    ans = params[:sort]&.to_sym

    if supported_sort_columns.include?(ans)
      ans
    else
      supported_sort_columns.first
    end
  end

  def show_title
    tc = t(category, scope: :category_names, default: category)
    t("categories_show_sort.#{sort_column}.title", category: tc)
  end
end
