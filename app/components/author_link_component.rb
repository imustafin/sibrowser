# frozen_string_literal: true

class AuthorLinkComponent < ViewComponent::Base
  def initialize(author:, author_itemprop: true)
    @author = author
    @author_itemprop = author_itemprop
  end

end
