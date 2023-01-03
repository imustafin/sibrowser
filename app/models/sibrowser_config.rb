class SibrowserConfig < ApplicationRecord

  CATEGORIES = [
    'anime',
    'gam',
    'fic',
    'mus',
    'pzl',
    'meme',
    'exact',
    'hum',
    'inet',
    'ero',
    'unk'
  ].freeze

  CATEGORIES_2 = [
    'anime',
    'videogames'
  ]

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
