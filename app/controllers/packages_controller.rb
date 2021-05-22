class PackagesController < ApplicationController
  helper_method :sort_column, :sort_direction

  def index
    @packages = Package.order(sort_column => sort_direction).page(params[:page]).per(10)
  end

  def show
    @package = Package.find(params[:id])
  end

  private

  def sort_column
    if %w[name authors published_at].include?(params[:sort])
      params[:sort].to_sym
    else
      :published_at
    end
  end

  def sort_direction
    if %w[asc desc].include?(params[:direction])
      params[:direction].to_sym
    else
      :asc
    end
  end

end
