module PackagesPagination
  extend ActiveSupport::Concern

  def packages_pagination(packages)
    @only_pagination = params.delete(:only_pagination)

    stream = []

    stream << turbo_stream.update(:pagination,
      inline: helpers.paginate(packages, window: 1, theme: 'infinite')
    )

    unless @only_pagination
      stream << turbo_stream.append(:packages,
        locals: { packages: },
        partial: 'packages_pagination/cards'
      )
    end

    render turbo_stream: stream
  end
end
