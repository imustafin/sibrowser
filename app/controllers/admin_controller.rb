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

  def cat_stats
    return head(:forbidden) unless helpers.admin?

    split = "split_part(x.key, '_', 4)"

    @cats = Package
      .from("#{Package.table_name}, jsonb_each_text(structure_classification) as x")
      .select("#{split} as cat, x.value as val, count(*) as count")
      .group("#{split}, x.value")
      .as_json
      .group_by { |x| x['cat'] }
      .transform_values do |v|
        [:yes, :null, :no].to_h do |val|
          row = v.find { |x| x['val'] == val.to_s }

          [val, row['count']]
        end
      end

    pp @cats
  end
end
