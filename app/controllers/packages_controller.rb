class PackagesController < ApplicationController

  def index
    @packages = Package.order(:id).page(params[:page]).per(10)
  end
end
