# frozen_string_literal: true

class AuthorsTableComponent < ViewComponent::Base
  def initialize(authors:, pagination: true)
    @authors = authors
    @pagination = pagination
  end

end
