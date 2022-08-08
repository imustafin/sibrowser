module Classification
  class Classifier
    # tf — Term Frequency
    # tf(t, d) relative frequency of term t in document d
    # tf(t, d) = f(t, d) / |d|
    # Where
    #   f(t, d) = how many times t occurs in d
    #   |d| = number of words (len(d))

    def initialize
      tmp = 'create temporary table'
      execute <<~SQL
        #{tmp}
        lens (
          package_id bigint,
          len int
        );

        #{tmp}
        tfs (
          package_id bigint,
          term text,
          tf float
        );

        #{tmp}
        idfs (
          term text,
          idf float
        )
      SQL

      model(:len) do
        belongs_to :package
      end
      fill_len

      model(:tf) do
        belongs_to :package
      end
      fill_tf

      model(:idf) do
        belongs_to :package
      end
      fill_idf
    end

    # len(d) is length of document d
    def fill_len
      lens = Package
        .from(Package.select(:id, unnest_ts))
        .select(:id, 'sum(array_length((ts).positions, 1)) as len')
        .group(:id)

      insert(Len, lens)
    end

    def fill_tf
      data = Package
        .from(Package.select(:id, unnest_ts))
        .joins("JOIN #{Len.table_name} ON id = package_id")
        .select(
          :id,
          '(ts).lexeme',
          '(array_length((ts).positions, 1)::float / len)'
        )

      insert(Tf, data)
    end

    def fill_idf
      n = Package.count # N = number of documents

      data = Package
        .from(Package.select(:id, unnest_ts))
        .group('(ts).lexeme')
        .select(
          '(ts).lexeme',
          "log(#{n}::float / count(*)::float)"
        )

      insert(Idf, data)
    end

    def model(name, &blk)
      cap = name.capitalize
      if self.class.const_defined?(cap)
        self.class.const_get(cap)
      else
        ans = self.class.const_set(cap, Class.new(ApplicationRecord) do
          instance_exec(self, &blk) if blk
        end
        )
      end
    end

    def unnest_ts(as = true)
      "unnest(category_ts) AS ts"
    end

    def execute(sql)
      ApplicationRecord.connection.execute(sql)
    end

    def insert(table, data)
      execute "insert into #{table.table_name} #{data.to_sql}"
    end
  end
end
