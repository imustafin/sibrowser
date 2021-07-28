# frozen_string_literal: true

class PackageCardComponent < ViewComponent::Base
  def initialize(package:)
    @package = package
  end

end
