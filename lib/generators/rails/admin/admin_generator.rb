module Rails::Generators
  class AdminGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_admin_files
      readme 'doc/admin.md'
    end
  end
end
