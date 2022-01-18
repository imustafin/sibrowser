# frozen_string_literal: true

class PackageCard::Component < ViewComponent::Base
  def initialize(package:, position:)
    @package = package
    @position = position
  end

  delegate :heroicon, to: :helpers

end
