class ParseUtils
  # Packages having this vk document in posts
  def self.packages_for_doc(document_id:, owner_id:)
    Package.where(<<~SQL, params: { d: document_id, o: owner_id }.to_json)
      jsonb_path_exists(posts,
        '$[*] ? (@.document_id == $d && @.owner_id == $o)',
        :params
      )
    SQL
  end
end
