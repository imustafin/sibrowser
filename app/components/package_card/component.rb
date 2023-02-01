# frozen_string_literal: true

class PackageCard::Component < ViewComponent::Base
  def initialize(package:, position:, options: nil)
    @package = package
    @position = position
    @options = options
  end

  delegate :heroicon, to: :helpers
end
