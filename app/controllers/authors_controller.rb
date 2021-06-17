class AuthorsController < ApplicationController
  include PackagesTable

  def show
    @author = params[:id]

    ps = table_packages

    ps = ps.by_author(@author)

    @package_count = Package.by_author(@author).count
    @other_authors = Package.by_author(@author)
      .pluck(:authors)
      .flatten
      .uniq(&:downcase)
      .delete_if { |x| x.downcase == @author.downcase }
      .sort

    @packages = ps

    @page_title = t('title_author', name: @author)
    @page_description = t('description_author', name: @author, package_count: @package_count)
    if @other_authors.present?
      @page_description += ' ' + t('description_author_coauthors', names: @other_authors.join(', '))
    end
  end
end
