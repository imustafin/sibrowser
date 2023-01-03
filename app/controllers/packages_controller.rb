class PackagesController < ApplicationController
  include PackagesPagination

  helper_method :vk_link, :vk_members_count, :download_stats, :packages, :page_title, :sort_column

  def index
    return packages_pagination(packages) if request.format.turbo_stream?

    page = params['page']

    if !page && sort_column == :published_at
      set_meta_tags site: nil
    else
      @page_title = page_title
      @page_title += ' ' + t('title_packages_page', page:) if page
    end

    empty = packages.size == 0
    set_meta_tags noindex: params[:q].present? || page.present? || empty
  end

  def packages
    @packages ||= begin
      p = Package.visible.order(sort_column => :desc, id: :desc)

      # Do this after order(sort_column) to first order by sort_column, then by search rank
      p = p.search_freetext(params[:q]) if params[:q].present?

      p = p.page(params[:page]).per(5)

      p
    end
  end

  def supported_sort_columns
    %i[published_at download_count]
  end

  def sort_column
    ans = params[:sort]&.to_sym

    if supported_sort_columns.include?(ans)
      ans
    else
      supported_sort_columns.first
    end
  end

  def page_title
    t("packages_index_sort.#{sort_column}.title")
  end

  def download_stats
    @download_stats ||= Package.download_stats
  end

  VK_SCREEN_NAME = 'sibrowser'.freeze

  def vk_link
    "https://vk.com/#{VK_SCREEN_NAME}"
  end

  def vk_members_count
    return if Rails.env.development? && !ENV['DO_VK_MEMBERS_COUNT']

    Rails.cache.fetch('vk_members_count', expires_in: 1.hour) do
      logger.info 'Fetching vk members count'

      members_count = 'members_count'

      vk_info = Vk.groups_get_by_id({
        group_id: VK_SCREEN_NAME,
        fields: members_count
      })['response'].first

      vk_info[members_count]
    end
  end

  def show
    id = params[:id]
    @package = Package.find_by(id:)

    unless @package
      superseder = Package.superseders(id).first

      if superseder
        redirect_to superseder, status: :moved_permanently
        return
      end

      raise ActionController::RoutingError, "Couldn't find Package '#{id}'"
    end

    @page_title = t(
      'title_package',
      name: @package.name,
      authors: @package.authors.present? ? " (#{@package.authors.join(', ')})" : ''
    )

    @page_description = helpers.package_description(@package)

    @breadcrumbs = {
      parts: [
        [t(:packages), packages_path],
        @package.name
      ]
    }
  end

  def direct_download
    package = Package.find(params[:package_id])

    url = package.vk_download_url

    return render html: "No download link", status: 404, layout: true unless url

    if request.is_crawler?
      msg = "Crawler '#{request.crawler_name}' tried direct download #{package.id}"
      Sentry.capture_message(msg) if Sentry.initialized?
      logger.info(msg)
      redirect_to url, allow_other_host: true
      # Don't bother fetching new url
      return
    end


    # Update and broadcast download counts
    package.with_lock do
      unless package.vk_download_url_fresh?
        new_url = fetch_new_vk_download_url(package)

        package.touch_vk_download_url
        package.vk_download_url = new_url

        url = new_url
      end

      package.add_download
      package.save!
    end

    package.broadcast_update_to(
      :download_counts,
      target: helpers.dom_id(package, :download_count),
      html: package.download_count
    )

    redirect_to url, allow_other_host: true
  end

  def fetch_new_vk_download_url(package)
    group_id, topic_id, start_comment_id = \
      package.source_link.scan(/vk\.com\/topic-(\d+)_(\d+)\?post=(\d+)/).first

    posts = Vk.board_get_comments(group_id:, topic_id:, start_comment_id:, count: 1)
    post = posts.dig('response', 'items', 0)

    return nil unless post['id'].to_s == start_comment_id

    doc = post['attachments'].find { |x| x.dig('doc', 'id')&.to_s == package.vk_document_id }


    doc&.dig('doc', 'url')
  end

  def logo
    package = Package.find(params[:package_id])

    if package.logo_bytes
      send_data package.logo_bytes,
        type: Si::Package::IMAGE_TYPE,
        disposition: :inline
    else
      render status: 404, body: ''
    end
  end

  def set_cat
    return head(:forbidden) unless helpers.admin?

    p = Package.find(params[:package_id])

    permitted = []
    p.structure.each_with_index do |round, round_id|
      round['themes'].each_with_index do |theme, theme_id|
        theme['questions'].each_with_index do |_, question_id|
          SibrowserConfig::CATEGORIES_2.each do |cat|
            permitted << [round_id, theme_id, question_id, cat].join('_')
          end
        end
      end
    end

    x = params.permit(*permitted).select { |k, v| %w[yes no].include?(v) }

    p.update!(structure_classification: x)

    flash[:set_cat] = "Saved at #{Time.now}"
    redirect_to p
  end
end
