class ApplicationController < ActionController::Base
  around_action :set_i18n_locale

  def default_url_options
    if I18n.locale != I18n.default_locale
      { locale: I18n.locale }
    else
      { locale: nil }
    end
  end

  protected

  def set_i18n_locale(&action)
    locale = if I18n.available_locales.map(&:to_s).include?(params[:locale])
               I18n.locale = params[:locale]
             else
               I18n.default_locale
             end
    I18n.with_locale(locale, &action)
  end
end
