# frozen_string_literal: true

class ProfileController < ApplicationController
  def bookmarks
    return packages_by_ids if request.format.turbo_stream?

    @page_title = t(:bookmarks)
    set_meta_tags noindex: true
  end

  # 204 No Content if all are missing
  def packages_by_ids
    ids = params[:ids][..SibrowserConfig::LOCAL_PAGINATION_SIZE].map(&:to_i)

    packages = Package.in_order_of(:id, ids).to_a

    response.set_header('SIB_FOUND_COUNT', packages.size)

    render turbo_stream: turbo_stream.append(:packages,
        locals: { packages: },
        partial: 'packages_pagination/cards_local'
      )
  end
end
