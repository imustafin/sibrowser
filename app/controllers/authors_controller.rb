class AuthorsController < ApplicationController
  include PackagesPagination

  helper_method :plot_data, :author, :all_packages, :package_count, :all_packages_count

  def index
    page = params[:page]

    @authors = Author.all.page(page).per(10)

    @page_title = t(:authors)

    set_meta_tags noindex: page.present?
  end

  def show
    return packages_pagination(all_packages) if request.format.turbo_stream?

    @breadcrumbs = {
      parts: [
        [t(:authors), authors_path],
        author
      ]
    }

    @page_title = t('title_author', name: author)

    return not_found unless all_packages.exists?

    @other_authors = Package.visible.by_author(author)
      .pluck(:authors)
      .flatten
      .uniq(&:downcase)
      .delete_if { |x| x.downcase == author.downcase }
      .sort

    @page_description = t('description_author', name: author, package_count: all_packages_count)
    if @other_authors.present?
      @page_description += ' ' + t('description_author_coauthors', names: @other_authors.join(', '))
    end

    set_meta_tags noindex: params['page'].present?
  end

  def all_packages_count
    all_packages.total_count
  end

  def author
    params[:id]
  end

  def all_packages
    Package.visible_paged(params[:page]).by_author(author)
  end

  def plot_data
    start = Date.today - 30

    dates = Package
      .by_author(params[:id])
      .download_counts
      .where('date >= ?', start)
      .to_h { |x| [x.date, x.count] }

    (start..Date.today).map do |date|
      [date, dates[date] || 0]
    end
  end

  def not_found
    @similar_authors = Author
      .similar(author)
      .limit(5)

    render :show_not_found, status: 404
  end
end
