class PackagesController < ApplicationController
  helper_method :sort_column, :sort_direction

  def index
    ps = Package

    ps = ps.order(sort_column => sort_direction) if sort_column && sort_direction

    ps = ps.page(params[:page]).per(10)

    # Do this after order(sort_column) to first order by sort_column, then by search rank
    ps = ps.search_freetext(params[:q]) if params[:q].present?

    @packages = ps
  end

  def show
    @package = Package.find(params[:id])
  end

  private

  def sort_column
    if %w[name authors published_at].include?(params[:sort])
      params[:sort].to_sym
    else
      params[:q].blank? ? :published_at : nil
    end
  end

  def sort_direction
    if %w[asc desc].include?(params[:direction])
      params[:direction].to_sym
    else
      params[:q].blank? ? :desc : nil
    end
  end
end
