# frozen_string_literal: true

class PackageCardsComponent < ViewComponent::Base
  def initialize(packages:)
    @packages = packages
    @first_index = (@packages.current_page - 1) * (@packages.limit_value) + 1
  end

end