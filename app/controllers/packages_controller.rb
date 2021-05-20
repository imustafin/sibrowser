class PackagesController < ApplicationController
  def index
    @packages = Package.order(:id).page(params[:page]).per(10)
  end

  def show
    @package = Package.find(params[:id])
  end
end
