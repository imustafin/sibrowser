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
        );

        #{tmp}
        pcategories (
          id int,
          package_id bigint,
          category text
        );

        #{tmp}
        aprioris (
          id int,
          category text,
          probability float
        )
      SQL

      model(:len) do
        belongs_to :package
      end
      report(Len) { fill_len }

      model(:tf) do
        belongs_to :package
      end
      report(Tf) { fill_tf }

      model(:idf)
      report(Idf) { fill_idf }

      model(:pcategory) do
        belongs_to :package
      end
      report(Pcategory) { fill_pcategory }

      model(:apriori)
      report(Apriori) { fill_apriori }
    end

    def report(model, &blk)
      puts "Filling #{model}"
      res = Benchmark.measure(&blk)
      puts "Filled #{model.count} of #{model} in #{res.total}"
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

    def fill_pcategory
      Package.where.not(tags: []).select(:id, :tags).find_in_batches do |batch|
        inserts = []

        batch.map do |p|
          next unless p.tags

          cats = p.tags.map { |t| category_by_tag(t) }.compact

          cats.compact.each do |cat|
            inserts << {
              package_id: p.id,
              category: cat
            }
          end
        end

        Pcategory.create!(inserts)
      end
    end

    def category_by_tag(tag)
      CAT_TO_TAG.find { |_, v| v.include?(tag.downcase.strip) }&.first
    end

    def fill_apriori
      distinct_ids = Pcategory.select(:package_id).distinct.count
      dict = Idf.count

      CAT_TO_TAG.keys.each do |category|
        this_cat = Pcategory.where(category:).count.to_f
        prob =  (this_cat + 1) / (distinct_ids + dict)
        Apriori.create!(
          category:,
          probability: prob
        )
      end
    end

    ## utils

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


    CAT_TO_TAG = {
      'anime' => [
        'аниме',
        'anime',
        'хентай',
        'ониме',
        'наруто',
        'аниме и все с ним связанное',
        'аниме(jojo)',
        'naruto',
      ],
      'music' => [
        'музыка',
        'музыкальный',
        'рок',
        'иностранный рок',
        'рэп',
        'рок, метал',
        'русский рок',
        'саундтреки',
        'саундтрек',
        'мэшапы',
        'music',
        'хип-хоп',
        'музло',
        'мешапы',
        'мелодии',
        'король и шут',
        'каверы',
        'альтернативный рок',
        'sopor aeternus & the ensemble of shadows',
        'группа "пикник"',
        'группа "кооператив ништяк"',
        'группа "lacrimosa"',
        'группа "nautilus pompilius"',
        'группа "the cure"',
        'группа "агата кристи"',
      ],
      'games' => [
        'игры',
        'видеоигры',
        'компьютерные игры',
        'league of legends',
        'хартстоун',
        'hearthstone',
        'игра escape from tarkov',
        'звуки из игр',
        'дота',
        'игровой',
        'игра auto chess',
        'игра',
        'игр',
        'warhammer 40k/fb/aos',
        'osu!',
        'osu! rhythm game',
        'games',
        'game',
        'cs:go без киберспорта',
      ],
      'movies' => [
        'кино',
        'фильмы',
        'сериалы',
        'кинопак',
        'мультфильмы',
        'мультсериалы',
        'мульты',
        'мультики',
        'киномир',
        'актёр',
        'актёры',
        'актрисы',
      ],
    }
  end
end
