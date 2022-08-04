module PackagesHelper
  def button_class(params = {})
    small = params[:type] == :small

    py = small ? 'py-1' : 'py-2'

    <<~CLASS.squish + ' '
      border-4 border-transparent
      inline-block cursor-pointer
      bg-purple-500 hover:border-purple-600
      #{py} px-4
      font-bold text-white
    CLASS
  end
end
