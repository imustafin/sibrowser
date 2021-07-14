class TagsController < ApplicationController
  def index
    @tags = Package
      .from(Package.select('jsonb_array_elements_text(tags) AS tag, id'))
      .where("tag <> ''")
      .group('lower(tag)')
      .order('COUNT(tag) DESC', 'MIN(subquery.id) DESC')
      .select('MIN(tag) AS tag', 'COUNT(tag) AS count')
      .page(params[:page]).per(10)

    @page_title = t(:tags)
  end
end
