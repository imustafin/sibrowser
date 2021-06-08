class PackagesController < ApplicationController
  include PackagesTable

  def index
    ps = table_packages

    # Do this after order(sort_column) to first order by sort_column, then by search rank
    ps = ps.search_freetext(params[:q]) if params[:q].present?

    @packages = ps
  end

  def show
    @package = Package.find(params[:id])
  end
end
