# frozen_string_literal: true

class PackagesPaginated::Component < ViewComponent::Base
  def initialize(packages:, order: nil)
    @packages = packages
    @first_index = (@packages.current_page - 1) * (@packages.limit_value) + 1
    @order = order
  end

  delegate :heroicon, to: :helpers

  def order_class(col)
    if col == @order
      'underline inline-block'
    else
      'font-bold inline-block'
    end
  end
end
