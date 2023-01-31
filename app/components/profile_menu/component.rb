# frozen_string_literal: true

class ProfileMenu::Component < ViewComponent::Base
  def initialize(class: nil)
    @class = binding.local_variable_get(:class)
  end
end
