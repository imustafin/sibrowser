class PackageSerializedToJsonb < ActiveRecord::Migration[6.1]
  class PackageOld < ApplicationRecord
    self.table_name = 'packages'

    serialize :authors, Array
    serialize :structure, Hash
    serialize :tags, Array
  end

  class PackageNew < ApplicationRecord
    self.table_name = 'packages'

    serialize :authors_old, Array
    serialize :structure_old, Hash
    serialize :tags_old, Array
  end

  def up
    change_table :packages do |t|
      t.jsonb :authors_new
      t.jsonb :structure_new
      t.jsonb :tags_new
    end

    PackageOld.find_each do |p|
      p.authors_new = p.authors
      p.structure_new = old_structure_to_new(p.structure)
      p.tags_new = p.tags

      p.save!
    end

    change_table :packages do |t|
      t.remove :authors
      t.rename :authors_new, :authors

      t.remove :structure
      t.rename :structure_new, :structure

      t.remove :tags
      t.rename :tags_new, :tags
    end
  end

  def down
    change_table :packages do |t|
      t.string :authors_old
      t.text :structure_old
      t.string :tags_old
    end

    PackageNew.find_each do |p|
      p.authors_old = p.authors
      p.structure_old = new_structure_to_old(p.structure)
      p.tags_old = p.tags

      p.save!
    end

    change_table :packages do |t|
      t.remove :authors
      t.rename :authors_old, :authors

      t.remove :structure
      t.rename :structure_old, :structure

      t.remove :tags
      t.rename :tags_old, :tags
    end
  end

  def old_structure_to_new(s)
    s.map do |round, themes_ar|
      themes = themes_ar.map do |theme, questions|
        {
          name: theme,
          questions: questions
        }
      end

      {
        name: round,
        themes: themes
      }
    end
  end

  def new_structure_to_old(s)
    s.map do |round|
      themes = round['themes'].map do |theme|
        [theme['name'], theme['questions']]
      end.to_h

      [round['name'], themes]
    end.to_h
  end
end
