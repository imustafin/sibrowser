class CategoriesController < ApplicationController
  include PackagesPagination

  helper_method :category, :packages, :show_title

  def index
    @categories = (SibrowserConfig::CATEGORIES + SibrowserConfig::CATEGORIES_2)
      .map { |c| [c, Package.by_category(c).count] }
      .sort_by(&:last)
      .reverse

    @page_title = t(:categories_page_title)
    @page_description = t(:categories_index_short_description)
  end

  def show
    if SibrowserConfig::CATEGORIES_2_MAPPING.key?(category)
      to = SibrowserConfig::CATEGORIES_2_MAPPING[category]

      return redirect_to allowed_params.merge(id: to), status: :moved_permanently
    end

    return packages_pagination(packages) if request.format.turbo_stream?

    package_count = packages.total_count

    @page_title = show_title
    old_description = t('description_category', category: category_translation, package_count:)
    @page_description = t(:description, scope: [:categories, category], default: old_description)

    set_meta_tags noindex: params['page'].present?

    @breadcrumbs = {
      parts: [
        [t(:categories_page_title), categories_path],
        category_translation
      ]
    }
  end

  def allowed_params
    params.permit(:id, :page, :sort)
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
    t("categories_show_sort.#{sort_column}.title", category: category_translation)
  end

  private

  def category_translation
    t(:name, scope: [:categories, category], default: category)
  end
end
