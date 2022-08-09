module Classification
  class Classifier
    # tf — Term Frequency
    # tf(t, d) relative frequency of term t in document d
    # tf(t, d) = f(t, d) / |d|
    # Where
    #   f(t, d) = how many times t occurs in d
    #   |d| = number of words (len(d))

    def initialize
      tmp = 'create temporary table if not exists'
      execute <<~SQL
        #{tmp}
        goodterms (
          term text
        );

        #{tmp}
        pcategories (
          package_id bigint,
          category text
        );

        #{tmp}
        aprioris (
          category text,
          probability float
        );

        #{tmp}
        termprobs (
          term text,
          category text,
          probability float
        );

        #{tmp}
        packprobs (
          package_id bigint,
          category text,
          probability float
        )
      SQL

      model(:goodterm)

      model(:pcategory) do
        belongs_to :package
      end

      model(:apriori)

      model(:termprob)

      model(:packprob)
    end

    def prepare
      report(Goodterm) { fill_goodterms }
      report(Pcategory) { fill_pcategory }
      report(Apriori) { fill_apriori }
      report(Termprob) { fill_termprobs }
      report(Packprob) { fill_packprobs }

      self
    end

    def report(model, &blk)
      puts "Filling #{model}"
      start = Time.now
      blk.call
      finish = Time.now
      puts "Filled #{model.count} of #{model} in #{(finish - start).round(2)}"
    end

    def fill_goodterms
      all_terms = Package
        .from(Package.select(unnest_ts))
        .select('(ts).lexeme as term')
        .distinct

      puts "Initial distinct terms #{Package.from(all_terms).count}"

      good_terms = Package
        .from(all_terms)
        .select('term')
        .where('char_length(term) > 2 or char_length(term) < 10')
        .where("term similar to '[a-zа-я]*'")

      puts "Cleaned terms #{Package.from(good_terms).count}"

      # insert(Goodterm, good_terms)
      insert(Goodterm, all_terms)
    end

    def fill_pcategory
      inserts = []
      Package.where.not(tags: []).select(:id, :tags).find_in_batches do |batch|
        batch.map do |p|
          next unless p.tags

          cats = p.tags.map { |t| category_by_tag(t) }.compact

          if cats.include?('anime')
            inserts << [p.id, 'anime']
          else
            inserts << [p.id, 'not_anime']
          end


          # cats.each do |cat|
          #   inserts << [p.id, cat]
          # end

          # (CAT_TO_TAG.keys - cats).each do |cat|
          #   inserts << [p.id, "not_#{cat}"]
          # end
        end
      end

      irows = inserts.map { |(a, b)| "(#{a}, '#{b}')" }.join(', ')
      insert(Pcategory, "values #{irows}")
    end

    def category_by_tag(tag)
      CAT_TO_TAG.find { |_, v| v.include?(tag.downcase.strip) }&.first
    end

    def fill_apriori
      distinct_ids = Pcategory.select(:package_id).count
      inserts = []

      all_cats = Pcategory.distinct.pluck(:category)

      all_cats.each do |category|
        this_cat = Pcategory.where(category:).count.to_f
        prob =  this_cat / distinct_ids

        inserts << [category, prob]
      end

      rows = inserts.map { |(a, b)| "('#{a}', #{b})" }.join(', ')

      insert(Apriori, "values #{rows}")
    end

    def fill_termprobs
      all_terms = Goodterm.all

      all_terms_n = Goodterm.count

      all_categories = Pcategory.select('category').distinct

      term_cat = Package
        .from(all_terms)
        .select('term', 'category')
        .joins("CROSS JOIN (#{all_categories.to_sql}) s")

      real_counts = Pcategory
        .joins("JOIN (#{Package.select('id', unnest_ts).to_sql}) s ON package_id = s.id")
        .joins("JOIN #{Goodterm.table_name} on term = (ts).lexeme")
        .group('category', '(ts).lexeme')
        .select(
          '(ts).lexeme AS term',
          'category',
          "sum(#{ts_occurs}) as real_count"
        )

      category_len = Package
        .from(real_counts)
        .select('category', 'sum(real_count) as category_len')
        .group('category')

      data = Package
        .from(term_cat)
        .select('term', 'category',
          # 'real_count', 'category_len',
          # Laplace smoothing here
          "(coalesce(real_count, 0) + 1)::float / (category_len + #{all_terms_n})")
        .joins("LEFT OUTER JOIN (#{real_counts.to_sql}) rr using (term, category)")
        .joins("JOIN (#{category_len.to_sql}) clen using(category)")

      insert(Termprob, data)
    end

    def fill_packprobs
      package_term_counts = Package
        .from(Package.select('id', unnest_ts))
        .select('id', '(ts).lexeme as term', "(#{ts_occurs}) as occurs")
        .joins("JOIN #{Goodterm.table_name} ON term = (ts).lexeme")

      package_tc_probs = Package
        .from(package_term_counts)
        .select('id', 'term', 'category', 'occurs * log(probability) as term_log_prob')
        .joins("JOIN #{Termprob.table_name} USING (term)")

      package_terms_log_prob = Package
        .from(package_tc_probs)
        .select('id', 'category', 'sum(term_log_prob) as term_log_prob_sum')
        .group('id', 'category')

      with_apriori = Package
        .from(package_terms_log_prob)
        .select('id', 'category',
          "(term_log_prob_sum + log(#{Apriori.table_name}.probability)) AS log_prob")
        .joins("JOIN #{Apriori.table_name} using (category)")


      pp Package.joins("JOIN (#{with_apriori.to_sql}) s USING (id)")
        .select('id', 'name', 'tags', 's.category', 'log_prob', "#{Pcategory.table_name}.category as pcat")
        .where("packages.tags <> '[]'")
        .where("#{Pcategory.table_name}.category = 'anime'")
         .where('id = 17004')
        .joins("JOIN #{Pcategory.table_name} on id = package_id")
        .limit(10)
        # .order('log_prob desc')
        .order(
          # :id,
          'log_prob desc'
        )
        .as_json



      raise 'kek'

    end


    ## utils

    def ts_occurs
      'array_length((ts).positions, 1)'
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
      "unnest(searchable) AS ts"
    end

    def execute(sql)
      ApplicationRecord.connection.execute(sql)
    end

    def insert(table, data)
      d = data.respond_to?(:to_sql) ? data.to_sql : data
      execute "insert into #{table.table_name} #{d}"
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
