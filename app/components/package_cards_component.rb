# frozen_string_literal: true

class PackageCardsComponent < ViewComponent::Base
  def initialize(packages:, first_index:)
    @packages = packages
    @first_index = first_index
  end

end
