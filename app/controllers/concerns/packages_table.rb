module PackagesTable
  extend ActiveSupport::Concern

  included do
    helper_method :sort_column, :sort_direction
  end

  private

  def any_sorting?
    [
      [sort_column, sort_direction].all?(&:present?),
      params[:sort].present?,
      params[:direction].present?
    ].all?(&:present?)
  end

  def table_packages
    ps = Package

    ps = ps.order(sort_column => sort_direction) if sort_column && sort_direction

    ps = ps.page(params[:page]).per(10)

    ps
  end

  def sort_column
    if %w[name authors published_at].include?(params[:sort])
      params[:sort].to_sym
    else
      params[:q].blank? ? :published_at : nil
    end
  end

  def sort_direction
    if %w[asc desc].include?(params[:direction])
      params[:direction].to_sym
    else
      params[:q].blank? ? :desc : nil
    end
  end
end
