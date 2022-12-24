# frozen_string_literal: true

class PackagesPaginated::Component < ViewComponent::Base
  def initialize(packages:, sort_provider: nil)
    @packages = packages
    @first_index = (@packages.current_page - 1) * (@packages.limit_value) + 1
    @sort_provider = sort_provider
  end

  delegate :heroicon, to: :helpers

  def sort_class(col)
    if col == @sort_provider.sort_column
      'underline inline-block'
    else
      'font-bold inline-block'
    end
  end

  def has_sort?
    !!@sort_provider
  end

  def sort_links
    sp = @sort_provider
    sp.supported_sort_columns.map.with_index do |col, i|
      x = {}
      cnt = [sp.controller_name, sp.action_name, 'sort'].join('_')
      x[:t] = [cnt, col.to_s, 'link'].join('.')

      at_default = i == 0
      p = sp.request.query_parameters.except(:page)
      x[:path] = url_for(at_default ? p.except(:sort) : p.merge(sort: col))

      x[:class] = col == sp.sort_column ? 'underline inline-block' : 'font-bold inline-block'

      x
    end
  end
end
