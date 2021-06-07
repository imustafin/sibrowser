class AuthorsController < ApplicationController
  def show
    @packages = Package.where('LOWER(authors::text)::jsonb @> to_jsonb(LOWER(?)::text)', params[:id])
  end
end
