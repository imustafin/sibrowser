class TagsController < ApplicationController
  include PackagesTable

  def index
    @tags = Package
      .from(Package.select('jsonb_array_elements_text(tags) AS tag, id'))
      .where("tag <> ''")
      .group('lower(tag)')
      .order('COUNT(tag) DESC', 'MIN(subquery.id) DESC')
      .select('MIN(tag) AS tag', 'COUNT(tag) AS count')
      .page(params[:page]).per(10)

    @page_title = t(:tags)

    if helpers.admin?
      @tags_to_cats = SibrowserConfig.instance.tags_to_cats || {}
      @cats = SibrowserConfig::CATEGORIES
    end
  end

  def show
    @tag = params[:id]

    ps = table_packages

    ps = ps.by_tag(@tag)

    @package_count = Package.by_tag(@tag).count

    @packages = ps

    @page_title = t('title_tag', tag: @tag)
    @page_description = t('description_tag', tag: @tag, package_count: @package_count)

    set_meta_tags noindex: any_sorting? || params['page'].present?
  end

  def toggle_cat
    return head(:forbidden) unless helpers.admin?

    SibrowserConfig.instance.toggle_tag_cat(params[:tag_id], params[:cat])
    redirect_to action: :index, params: { page: params[:page] }
  end
end
