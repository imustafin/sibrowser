module Classification
  class Classifier
    def initialize(tag)
      @tag = tag

      execute <<~SQL
        CREATE TEMP TABLE idf(
          lexeme text,
          df integer,
          idf float
        );

        CREATE INDEX ON idf(lexeme);

        CREATE TEMP TABLE tag_tfidf(
          lexeme text,
          tfidf float
        );

        CREATE TEMP TABLE package_len(
          package_id bigint,
          len int
        );

        CREATE INDEX ON package_len(package_id);

        CREATE TEMP TABLE package_lexemes(
          package_id bigint,
          lexeme text,
          occurences int,
          freq float,
          tfidf float
        );

        CREATE INDEX ON package_lexemes(package_id);
        CREATE INDEX ON package_lexemes(lexeme);
      SQL

      @idf = Class.new(ApplicationRecord) do
        self.table_name = 'idf'
      end

      @tag_tfidf = Class.new(ApplicationRecord) do
        self.table_name = 'tag_tfidf'
      end

      @package_tfidf = Class.new(ApplicationRecord) do
        self.table_name = 'package_tfidf'
      end

      @package_len = Class.new(ApplicationRecord) do
        self.table_name = 'package_len'
      end

      @package_lexemes = Class.new(ApplicationRecord) do
        self.table_name = 'package_lexemes'
      end

      fill_idf
      execute "ANALYZE idf;"

      # fill_tag_tfidf

      # fill_package_tfidf

      fill_package_len
      execute "ANALYZE package_len;"

      fill_package_lexemes
      execute "ANALYZE package_lexemes"
      set_package_lexemes_freq
      set_package_lexemes_tfidf
    end

    # IDF for all lexemes
    def idf
      @idf
    end

    # Average TF-IDF for lexemes of docs with this tag
    def tag_tfidf
      @tag_tfidf
    end

    def magn
      @magn
    end

    def package_tfidf
      @package_tfidf
    end

    def package_len
      @package_len
    end

    def package_lexemes
      @package_lexemes
    end

    def fill_idf
      package_count = Package.count
      occurences = 'SUM(array_length((ts).positions, 1))'

      data = Package
        .from(Package.select(unnest_ts))
        .group('(ts).lexeme')
        .having("#{occurences} > 1")
        .select(Arel.sql(<<~SQL))
          (ts).lexeme,
          #{occurences},
          log(#{package_count}::float / #{occurences})
        SQL


      execute <<~SQL
        INSERT INTO #{idf.table_name}
        #{data.to_sql}
      SQL

      Rails.logger.info "Computed IDF for #{idf.count} lexemes"
    end

    def fill_tag_tfidf
      data = Package
        .from(Package.select(unnest_ts, length_ts).by_tag(@tag))
        .group('(ts).lexeme')
        .joins("INNER JOIN #{idf.table_name} ON (ts).lexeme = idf.lexeme")
        .select(Arel.sql(<<~SQL))
          (ts).lexeme,
          MIN(idf.idf) * AVG(array_length((ts).positions, 1)::float / length_ts)
        SQL

      execute <<~SQL
        INSERT INTO #{tag_tfidf.table_name}
        #{data.to_sql}
      SQL
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
      with_idf = Package
        .from(Package.select('id', unnest_ts, length_ts))
        .joins("INNER JOIN #{idf.table_name} ON (ts).lexeme = idf.lexeme")
        .select('id', 'ts', 'length_ts', 'idf')

      data = Package
        .from(with_idf)
        .group('id', 'ts')
        .select(Arel.sql(<<~SQL))
          id,
          (ts).lexeme,
          MIN(idf) * array_length((ts).positions, 1)::float / MIN(length_ts)
        SQL

      execute <<~SQL
        INSERT INTO #{package_tfidf.table_name}
        #{data.to_sql}
      SQL
    end

    def fill_package_len
      data = Package
        .select('id', length_ts)

      execute <<~SQL
        INSERT INTO #{package_len.table_name}
        #{data.to_sql}
      SQL
    end

    def fill_package_lexemes
      data = Package
        .from(Package.select('id', unnest_ts))
        .group('id', 'ts')
        .select('id', '(ts).lexeme', 'SUM(array_length((ts).positions, 1))')

      execute <<~SQL
        INSERT INTO #{package_lexemes.table_name}
        #{data.to_sql}
      SQL
    end

    def set_package_lexemes_freq
      execute <<~SQL
        UPDATE package_lexemes
        SET freq = occurences::float / len
        FROM package_len
        WHERE package_lexemes.package_id = package_len.package_id
      SQL
    end

    def set_package_lexemes_tfidf
      execute <<~SQL
        UPDATE #{package_lexemes.table_name}
        SET tfidf = freq * idf
        FROM #{idf.table_name}
        WHERE package_lexemes.lexeme = idf.lexeme
      SQL
    end

    def tsv(s)
      "to_tsvector('russian', jsonb_path_query_array(structure, '#{s}'))"
    end

    def ts_expr
      <<~SQL
        #{tsv('$[*].themes[*].questions[*].answers[*]')}
        ||
        #{tsv('$[*].themes[*].questions[*].question_text')}
      SQL
    end

    def unnest_ts
      "unnest(#{ts_expr}) AS ts"
    end

    def length_ts
      "length(#{ts_expr}) AS length_ts"
    end

    def execute(sql)
      ApplicationRecord.connection.execute(sql)
    end
  end
end
