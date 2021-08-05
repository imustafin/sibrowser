class AuthorsController < ApplicationController
  def index
    @authors = Package
      .from(Package.visible.select('jsonb_array_elements_text(authors) AS author, id'))
      .group('lower(author)')
      .order('COUNT(author) DESC', 'MIN(subquery.id) DESC')
      .select('MIN(author) AS author', 'COUNT(author) AS count')
      .page(params[:page]).per(10)

    @page_title = t(:authors)
  end

  def show
    @author = params[:id]

    @packages = Package.visible_paged(params[:page]).by_author(@author)

    @package_count = @packages.total_count
    @other_authors = Package.visible.by_author(@author)
      .pluck(:authors)
      .flatten
      .uniq(&:downcase)
      .delete_if { |x| x.downcase == @author.downcase }
      .sort

    @page_title = t('title_author', name: @author)
    @page_description = t('description_author', name: @author, package_count: @package_count)
    if @other_authors.present?
      @page_description += ' ' + t('description_author_coauthors', names: @other_authors.join(', '))
    end

    set_meta_tags noindex: params['page'].present?

    @breadcrumbs = {
      parts: [
        [t(:authors), authors_path],
        @author
      ]
    }
  end
end
