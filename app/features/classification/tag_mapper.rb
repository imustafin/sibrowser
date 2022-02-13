module Classification
  class TagMapper
    def initialize
      refresh = false
      refresh = true

      if refresh
        execute <<~SQL
          DROP TABLE IF exists tag_mapped;
        SQL
      end

      execute <<~SQL
        CREATE TABLE IF NOT EXISTS tag_mapped(
          id bigint,
          category text,
          weight float
        );

        CREATE INDEX ON tag_mapped(id);
      SQL

      @tag_mapped = Class.new(ApplicationRecord) do
        self.table_name = 'tag_mapped'
      end

      fill_tag_mapped
      execute 'ANALYZE tag_mapped;'
    end

    def tag_mapped
      @tag_mapped
    end

    def fill_tag_mapped
      Package.where.not(tags: []).select(:id, :tags).find_in_batches do |batch|
        inserts = []

        batch.map do |p|
          cats = p.tags.map { |t| category_by_tag(t) }

          n = cats.size

          cats.tally.each do |cat, num|
            next unless cat

            inserts << {
              id: p.id,
              category: cat,
              weight: num.to_f / n
            }
          end
        end

        tag_mapped.create!(inserts)
      end
    end

    def category_by_tag(tag)
      CONFIG.find { |_, v| v.include?(tag.downcase.strip) }&.first
    end

    # category to tags
    CONFIG = {
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

    def execute(sql)
      ApplicationRecord.connection.execute(sql)
    end
  end
end
