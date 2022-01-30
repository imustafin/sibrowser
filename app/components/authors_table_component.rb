# frozen_string_literal: true

class AuthorsTableComponent < ViewComponent::Base
  include ViewComponent::Translatable

  def initialize(authors:, pagination: true)
    @authors = authors
    @pagination = pagination
  end

end
