class SibrowserConfig < ApplicationRecord
  QUESTION_TYPES = %i[
    text
    image
    voice
    video
  ]

  CATEGORIES = [
    'pzl',
    'exact',
    'inet',
    'ero',
    'unk'
  ].freeze

  CATEGORIES_2 = [
    'anime',
    'videogames',
    'music',
    'movies',
    'social',
    'meme'
  ]

  CATEGORIES_2_MAPPING = {
    'gam' => 'videogames',
    'mus' => 'music',
    'fic' => 'movies',
    'hum' => 'social'
  }

  def self.instance
    first_or_create
  end

  def toggle_tag_cat(tag, cat)
    ttc = tags_to_cats&.to_h || {}
    cur_cats = ttc[tag] || []
    if cur_cats.include?(cat)
      cur_cats -= [cat]
    else
      cur_cats += [cat]
    end

    ttc[tag] = cur_cats

    self.tags_to_cats = ttc
    save!
  end
end
