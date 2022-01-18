# frozen_string_literal: true

class PackageCardComponent < ViewComponent::Base
  def initialize(package:, position:)
    ActiveSupport::Deprecation
      .warn('PackageCardComponent deprecated, use PackageCard::Component')

    @package = package
    @position = position
  end

end
