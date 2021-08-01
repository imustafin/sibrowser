# frozen_string_literal: true

class PackageCardComponent < ViewComponent::Base
  def initialize(package:, position:)
    @package = package
    @position = position
  end

end
