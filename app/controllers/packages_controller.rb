class PackagesController < ApplicationController
  def index
    @packages = Package.all
  end
end
