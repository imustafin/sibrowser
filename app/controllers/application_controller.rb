class ApplicationController < ActionController::Base
  before_action :set_i18n_locale

  def default_url_options
    if I18n.locale != I18n.default_locale
      { locale: I18n.locale }
    else
      {}
    end
  end

  protected

  def set_i18n_locale
    if I18n.available_locales.map(&:to_s).include?(params[:locale])
      I18n.locale = params[:locale]
    end
  end
end
