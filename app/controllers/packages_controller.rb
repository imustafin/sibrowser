class PackagesController < ApplicationController
  def index
    @packages = Package.order(:published_at).page(params[:page]).per(10)
  end

  def show
    @package = Package.find(params[:id])
  end
end
