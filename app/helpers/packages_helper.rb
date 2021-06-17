module PackagesHelper
  def button_class(params = {})
    small = params[:type] == :small

    py = small ? 'py-1' : 'py-2'

    "border-4 border-transparent inline-block bg-purple-500 #{py} px-4 font-bold text-white hover:border-purple-600 "
  end
end
