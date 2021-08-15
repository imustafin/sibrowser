class AuthorsController < ApplicationController
  def index
    @authors = Author.all.page(params[:page]).per(10)

    @page_title = t(:authors)
  end

  def show
    @author = params[:id]

    @packages = Package.visible_paged(params[:page]).by_author(@author)

    @breadcrumbs = {
      parts: [
        [t(:authors), authors_path],
        @author
      ]
    }

    @page_title = t('title_author', name: @author)

    return not_found unless @packages.exists?


    @package_count = @packages.total_count
    @other_authors = Package.visible.by_author(@author)
      .pluck(:authors)
      .flatten
      .uniq(&:downcase)
      .delete_if { |x| x.downcase == @author.downcase }
      .sort

    @page_description = t('description_author', name: @author, package_count: @package_count)
    if @other_authors.present?
      @page_description += ' ' + t('description_author_coauthors', names: @other_authors.join(', '))
    end

    set_meta_tags noindex: params['page'].present?

  end

  def not_found
    @similar_authors = Author
      .similar(@author)
      .limit(5)

    render :show_not_found, status: 404
  end
end
