class Author
  def self.base
    Package
      .from(Package.visible.select('jsonb_array_elements_text(authors) AS author, id'))
      .group('lower(author)')
      .select('MIN(author) AS author', 'COUNT(author) AS count')
  end

  def self.all
    base
      .order('COUNT(author) DESC', 'MIN(subquery.id) DESC')
  end

  def self.similar(author)
    similarity = Arel::Nodes::InfixOperation.new(
      '<->',
      Arel.sql('MIN(author)'),
      Arel::Nodes.build_quoted(author)
    )

    base
      .order(similarity)
  end
end
