class PackagesController < ApplicationController
  def index
    @packages = Package.visible_paged(params[:page])

    # Do this after order(sort_column) to first order by sort_column, then by search rank
    @packages = @packages.search_freetext(params[:q]) if params[:q].present?

    if params['page']
      @page_title = t('title_packages_page', page: params['page'])
    end

    set_meta_tags noindex: params[:q].present? || params['page'].present?

    @only_pagination = params.delete(:only_pagination)

    respond_to do |f|
      f.turbo_stream
      f.html
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

    if helpers.admin?
      @cats = SibrowserConfig::CATEGORIES
    end

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

    unless url
      render html: "No download link", status: 404, layout: true
    else
      package.increment!(:download_count)
      package.broadcast_update_to(
        :download_counts,
        target: helpers.dom_id(package, :download_count),
        html: package.download_count
      )

      redirect_to url, allow_other_host: true
    end
  end

  def set_cat
    return head(:forbidden) unless helpers.admin?

    p = Package.find(params[:package_id])


    mc = p.manual_categories || {}
    mc = [] unless mc.is_a?(Hash)

    if params[:question].present? && mc.dig(params[:round], params[:theme], params[:question]) == params[:cat]
      new_cat = nil
    else
      new_cat = params[:cat]
    end

    question_ids = params[:question]

    if params[:question].present?
      question_ids = [params[:question]]
    else
      r = p.structure[params[:round].to_i]
      t = r['themes'][params[:theme].to_i]['questions']
      question_ids = (0...t.length).map(&:to_s)
    end

    upd = {
      params[:round] => {
        params[:theme] => question_ids.map { |id| [id, new_cat] }.to_h
      }
    }

    mc = mc.deep_merge(upd)
    p.manual_categories = mc
    p.save!

    anchor = [params[:round], params[:theme], params[:question]].reject(&:blank?).join('_')

    redirect_to action: :show, id: params[:package_id], anchor: anchor
  end
end
