# frozen_string_literal: true

class AuthorLinkComponent < ViewComponent::Base
  def initialize(author:)
    @author = author
  end

end
