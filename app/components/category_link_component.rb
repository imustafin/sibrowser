# frozen_string_literal: true

class CategoryLinkComponent < ViewComponent::Base
  def initialize(category:)
    @category = category
  end

  def category_name
    @category.first
  end

  def category_ratio
    @category.last
  end
end
