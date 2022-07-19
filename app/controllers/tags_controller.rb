class TagsController < ApplicationController
  include PackagesPagination

  helper_method :tag_id, :packages

  def index
    page = params[:page]

    @tags = Package
      .from(Package.visible.select('jsonb_array_elements_text(tags) AS tag, id'))
      .where("tag <> ''")
      .group('lower(tag)')
      .order('COUNT(tag) DESC', 'MIN(subquery.id) DESC')
      .select('MIN(tag) AS tag', 'COUNT(tag) AS count')
      .page(page).per(10)

    @page_title = t(:tags)

    if helpers.admin?
      @tags_to_cats = SibrowserConfig.instance.tags_to_cats || {}
      @cats = SibrowserConfig::CATEGORIES
    end

    set_meta_tags noindex: page.present?
  end

  def show
    return packages_pagination(packages) if request.format.turbo_stream?

    package_count = packages.total_count

    @page_title = t('title_tag', tag: tag_id)
    @page_description = t('description_tag', tag: tag_id, package_count:)

    set_meta_tags noindex: params['page'].present?

    @breadcrumbs = {
      parts: [
        [t(:tags), tags_path],
        tag_id
      ]
    }
  end

  def tag_id
    params[:id]
  end

  def packages
    Package.visible_paged(params[:page]).by_tag(tag_id)
  end

  def toggle_cat
    return head(:forbidden) unless helpers.admin?

    SibrowserConfig.instance.toggle_tag_cat(params[:tag_id], params[:cat])
    redirect_to action: :index, params: { page: params[:page] }
  end
end
