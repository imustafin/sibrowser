class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.arel_cast(x, type)
    arel_f('CAST', x.as(type.to_s))
  end

  def self.arel_f(f, *args)
    Arel::Nodes::NamedFunction.new(f, [args])
  end
end
