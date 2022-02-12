module Classification
  class Classifier
    def initialize
      refresh = false
      refresh = true

      if refresh
        execute <<~SQL
          DROP TABLE IF EXISTS idf;
          DROP TABLE IF EXISTS package_tfidf;
          DROP TABLE IF EXISTS best_sims;
          DROP TABLE IF EXISTS magns;
        SQL
      end

      execute <<~SQL
        CREATE TABLE IF NOT EXISTS idf(
          lexeme text PRIMARY KEY,
          df integer,
          idf float
        );

        CREATE TABLE IF NOT EXISTS package_tfidf(
          package_id bigint,
          lexeme text,
          tfidf float,
          occurs integer
        );

        CREATE TABLE IF NOT EXISTS magns(
          id bigint PRIMARY KEY,
          magn float
        );

        CREATE INDEX IF NOT EXISTS a ON package_tfidf(package_id);
        CREATE INDEX IF NOT EXISTS b ON package_tfidf(lexeme);
        CREATE INDEX IF NOT EXISTS c ON package_tfidf(package_id, lexeme);

        CREATE TABLE IF NOT EXISTS best_sims(
          package_id bigint PRIMARY KEY,
          sim_td bigint,
          sim float
        );
      SQL

      @idf = Class.new(ApplicationRecord) do
        self.table_name = 'idf'
      end

      @package_tfidf = Class.new(ApplicationRecord) do
        self.table_name = 'package_tfidf'
      end

      @best_sims = Class.new(ApplicationRecord) do
        self.table_name = 'best_sims'
      end

      @magns = Class.new(ApplicationRecord) do
        self.table_name = 'magns'
      end

      if refresh
        fill_idf
        execute "ANALYZE idf;"

        fill_package_tfidf
        execute "ANALYZE package_tfidf"

        fill_magns
        execute "ANALYZE magns"
      end

      fill_best_sims
    end

    # IDF for all lexemes
    def idf
      @idf
    end

    def magns
      @magns
    end

    def package_tfidf
      @package_tfidf
    end

    def fill_idf
      package_count = Package.count
      packages = 'COUNT(id)'

      data = Package
        .from(Package.select('id', unnest_ts))
        .group('(ts).lexeme')
        .select(Arel.sql(<<~SQL))
          (ts).lexeme,
          #{packages},
          log(#{package_count}::float / #{packages})
        SQL

      execute <<~SQL
        INSERT INTO #{idf.table_name}
        #{data.to_sql}
      SQL

      Rails.logger.info "Computed IDF for #{idf.count} lexemes"
    end

    def fill_magn
      data = Package
        .from("(#{Package.select('id', unnest_ts, length_ts).to_sql}) AS orig")
        .group('orig.id')
        .joins("INNER JOIN #{idf.table_name} ON (ts).lexeme = idf.lexeme")
        .select(Arel.sql(<<~SQL))
          orig.id,
          SQRT(
            SUM(
              (idf.idf * array_length((ts).positions, 1)::float / length_ts)
              ^ 2
            )
          )
        SQL

      execute <<~SQL
        INSERT INTO #{magn.table_name}
        #{data.to_sql}
      SQL
    end

    def fill_package_tfidf
      lexemes = Package
        .from("(#{Package.select('id', unnest_ts).to_sql}) lexemes_join")
        .joins("INNER JOIN #{idf.table_name} ON (ts).lexeme = idf.lexeme")
        .select('id', 'ts')

      lengths = Package
        .from(lexemes)
        .group('id')
        .select('id', 'SUM(array_length((ts).positions, 1)) AS length')

      idfs = Package
        .from(lexemes)
        .joins("INNER JOIN #{idf.table_name} ON (ts).lexeme = idf.lexeme")
        .select('id', '(ts).lexeme', 'idf')

      tfs = Package
        .from(lexemes)
        .group('id', 'ts')
        .select('id', '(ts).lexeme', 'SUM(array_length((ts).positions, 1)) AS occurs')

      data = Package
        .from("(#{lengths.to_sql}) AS lengths")
        .joins("INNER JOIN (#{idfs.to_sql}) idfs ON idfs.id = lengths.id")
        .joins("INNER JOIN (#{tfs.to_sql}) tfs ON tfs.id = idfs.id AND tfs.lexeme = idfs.lexeme")
        .select(Arel.sql(<<~SQL))
          lengths.id,
          idfs.lexeme,
          idfs.idf * tfs.occurs / lengths.length,
          tfs.occurs
        SQL

      execute <<~SQL
        INSERT INTO #{package_tfidf.table_name}
        #{data.to_sql}
      SQL
    end

    def fill_magns
      data = Package
        .from("#{package_tfidf.table_name}")
        .group('package_id')
        .select('package_id AS id', 'SQRT(SUM(tfidf ^ 2)) AS magn')

      execute <<~SQL
        INSERT INTO #{magns.table_name}
        #{data.to_sql}
      SQL
    end

    def fill_best_sims
      return

      right_lexemes = Package
        .from(Package.select('id'))
        .joins("INNER JOIN #{package_tfidf.table_name} ON id = package_tfidf.package_id")
        .select('id', 'package_tfidf.lexeme', 'package_tfidf.tfidf')

      left_lexemes = Package
        .from(Package.select('id'))
        .joins("INNER JOIN #{package_tfidf.table_name} ON id = package_tfidf.package_id")
        .select('id', 'package_tfidf.lexeme', 'package_tfidf.tfidf')

      ab = Package
        .from("(#{left_lexemes.to_sql}) AS a")
        .joins("INNER JOIN (#{right_lexemes.to_sql}) b ON a.lexeme = b.lexeme")
        .joins("INNER JOIN #{magns.table_name} left_magn ON a.id = left_magn.id")
        .joins("INNER JOIN #{magns.table_name} right_magn ON b.id = right_magn.id")
        .group('a.id', 'b.id')
        .select('a.id', 'b.id', '(SUM(a.tfidf * b.tfidf) / (MIN(left_magn.magn) * MIN(right_magn.magn))) AS sim')
    end

    def unnest_ts
      "unnest(category_ts) AS ts"
    end

    def execute(sql)
      ApplicationRecord.connection.execute(sql)
    end
  end
end
