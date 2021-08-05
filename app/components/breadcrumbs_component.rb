# frozen_string_literal: true

class BreadcrumbsComponent < ViewComponent::Base
  def initialize(parts:)
    @parts = parts
  end

end
