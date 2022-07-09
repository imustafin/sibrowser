class Author
  def self.base
    Package
      .from(
        Package.visible.select(
          'id',
          'jsonb_array_elements_text(authors) AS author',
          'download_count'
        )
      )
      .group('lower(author)')
      .select(
        'MAX(author) AS author', # Capitals are greater
        'COUNT(author) AS count',
        'SUM(download_count) AS total_downloads'
      )
      .where('author IS NOT NULL')
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
