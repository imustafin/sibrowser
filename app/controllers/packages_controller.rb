class PackagesController < ApplicationController
  def index
    @packages = Package.order(:id).page(params[:page])
  end
end
