# frozen_string_literal: true

class KeywordLinksComponent < ViewComponent::Base
  def initialize(tags:, categories:)
    @tags = tags
    @categories = categories
  end

end
