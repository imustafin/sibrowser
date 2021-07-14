class AdminController < ApplicationController
  def index
  end

  def login
    good_login = ActiveSupport::SecurityUtils.secure_compare(
      params[:login],
      ENV['ADMIN_LOGIN']
    )

    good_password = ActiveSupport::SecurityUtils.secure_compare(
      params[:password],
      ENV['ADMIN_PASSWORD']
    )

    if good_login && good_password
      session[:admin] = true
      redirect_to root_path
    else
      flash[:notice] = 'wrong'
      redirect_to admin_path
    end
  end

  def logout
    session.delete(:admin)
    redirect_to root_path
  end
end
