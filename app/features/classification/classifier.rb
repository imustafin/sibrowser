module Classification
  class Classifier
    attr_accessor :tid


    def model(name, **cols, &blk)
      self.class.attr_accessor(name)

      tablename = "#{name}_#{tid}"

      execute <<~SQL
        create temporary table #{tablename}
        (
          #{cols.map { |k, v| "#{k} #{v}" }.join(', ')}
        );
      SQL

      instance_variable_set(
        "@#{name}",
        Class.new(ApplicationRecord) do
          self.table_name = tablename

          instance_exec(self, &blk) if blk
        end
      )
    end

    def initialize
      @tid = SecureRandom.urlsafe_base64(5).downcase

      model(:goodterm, term: :text)
      model(:pcategory, package_id: :bigint, category: :text) { belongs_to :package }
      model(:apriori, category: :text, probability: :float)
      model(:termprob, term: :text, category: :text, probability: :float)
      model(:packprob, package_id: :bigint, category: :text, probability: :float)
    end

    def prepare
      report(:goodterm)
      report(:pcategory)
      report(:apriori)
      report(:termprob)
      report(:packprob)

      self
    end

    def report(model, &blk)
      puts "Filling #{model}"
      start = Time.now
      send("fill_#{model}")
      finish = Time.now
      puts "Filled #{send(model).count} of #{model} in #{(finish - start).round(2)}"
    end

    def fill_goodterm
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
      insert(goodterm, all_terms)
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
      insert(pcategory, "values #{irows}")
    end

    def category_by_tag(tag)
      CAT_TO_TAG.find { |_, v| v.include?(tag.downcase.strip) }&.first
    end

    def fill_apriori
      distinct_ids = pcategory.select(:package_id).count
      inserts = []

      all_cats = pcategory.distinct.pluck(:category)

      all_cats.each do |category|
        this_cat = pcategory.where(category:).count.to_f
        prob =  this_cat / distinct_ids

        inserts << [category, prob]
      end

      rows = inserts.map { |(a, b)| "('#{a}', #{b})" }.join(', ')

      insert(apriori, "values #{rows}")
    end

    def fill_termprob
      all_terms = goodterm.all

      all_terms_n = goodterm.count

      all_categories = pcategory.select('category').distinct

      term_cat = Package
        .from(all_terms)
        .select('term', 'category')
        .joins("CROSS JOIN (#{all_categories.to_sql}) s")

      real_counts = pcategory
        .joins("JOIN (#{Package.select('id', unnest_ts).to_sql}) s ON package_id = s.id")
        .joins("JOIN #{goodterm.table_name} on term = (ts).lexeme")
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

      insert(termprob, data)
    end

    def fill_packprob
      package_term_counts = Package
        .from(Package.select('id', unnest_ts))
        .select('id', '(ts).lexeme as term', "(#{ts_occurs}) as occurs")
        .joins("JOIN #{goodterm.table_name} ON term = (ts).lexeme")

      package_tc_probs = Package
        .from(package_term_counts)
        .select('id', 'term', 'category', 'occurs * log(probability) as term_log_prob')
        .joins("JOIN #{termprob.table_name} USING (term)")

      package_terms_log_prob = Package
        .from(package_tc_probs)
        .select('id', 'category', 'sum(term_log_prob) as term_log_prob_sum')
        .group('id', 'category')

      with_apriori = Package
        .from(package_terms_log_prob)
        .select('id', 'category',
          "(term_log_prob_sum + log(#{apriori.table_name}.probability)) AS log_prob")
        .joins("JOIN #{apriori.table_name} using (category)")


      pp Package.joins("JOIN (#{with_apriori.to_sql}) s USING (id)")
        .select('id', 'name', 'tags', 's.category', 'log_prob', "#{pcategory.table_name}.category as pcat")
        .where("packages.tags <> '[]'")
        .where("#{pcategory.table_name}.category = 'anime'")
         .where('id = 17004')
        .joins("JOIN #{pcategory.table_name} on id = package_id")
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
