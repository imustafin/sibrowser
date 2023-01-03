class MergeByFileHash < ActiveRecord::Migration[7.0]
  class Package < ApplicationRecord
    def supersede!(p)
      with_lock do
        superseded_ids << p.id

        p.downloads.each do |k, v|
          downloads[k] ||= 0
          downloads[k] += v
        end

        self.posts = (posts + p.posts).uniq { |x| x['link'] }

        p.destroy!
        save!
      end
    end
  end

  def change
    hashes = Package.group(:file_hash).having('count(*) > 1').pluck(:file_hash)
    hashes.compact! # remove nil

    hashes.each do |file_hash|
      into, *others = Package.where(file_hash:).to_a

      others.each do |p|
        into.supersede!(p)
      end
    end

    Package.delete_by(file_hash: nil)

    add_index :packages, :file_hash, unique: true
  end
end
