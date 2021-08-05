class TagsController < ApplicationController
  def index
    @tags = Package
      .from(Package.visible.select('jsonb_array_elements_text(tags) AS tag, id'))
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

    @packages = Package.visible_paged(params[:page]).by_tag(@tag)

    @package_count = @packages.total_count

    @page_title = t('title_tag', tag: @tag)
    @page_description = t('description_tag', tag: @tag, package_count: @package_count)

    set_meta_tags noindex: params['page'].present?

    @breadcrumbs = {
      parts: [
        [t(:tags), tags_path],
        @tag
      ]
    }
  end

  def toggle_cat
    return head(:forbidden) unless helpers.admin?

    SibrowserConfig.instance.toggle_tag_cat(params[:tag_id], params[:cat])
    redirect_to action: :index, params: { page: params[:page] }
  end
end
