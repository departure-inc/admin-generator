module Rails::Generators
  class AdminGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_controller
      template 'controller.rb.tt',
               "app/controllers/admin/#{plural_name}_controller.rb"
    end

    def create_views
      %w[index show new edit _form _search_form].each do |view|
        template "views/#{view}.html.slim.tt",
                 "app/views/admin/#{plural_name}/#{view}.html.slim"
      end
    end

    def inject_routes
      inject_into_file 'config/routes/admin.rb',
                       "  resources :#{plural_name}\n",
                       after: "namespace :admin do\n"
    end

    def inject_sidebar
      inject_into_file 'app/views/admin/shared/_sidebar.html.slim',
                       sidebar_link,
                       after: "/ ナビゲーションリンクは rails g admin <ModelName> で自動追加されます\n"
    end

    def inject_ransack_allowlist
      inject_into_class "app/models/#{file_path}.rb", class_name, ransack_allowlist
    end

    private

    def model_class
      class_name.constantize
    end

    def model_columns
      model_class.columns
    end

    def form_columns
      excluded = %w[id created_at updated_at]
      model_columns.reject { |c| excluded.include?(c.name) || c.name.end_with?('_digest') }
    end

    def search_columns
      form_columns.select { |c| %i[string text].include?(c.type) }
    end

    def freeword_attribute
      "#{search_columns.map(&:name).join('_or_')}_cont"
    end

    def ransack_allowlist
      <<~RUBY.indent(2)

        def self.ransackable_attributes(auth_object = nil)
          %w(#{search_columns.map(&:name).join(' ')})
        end

        def self.ransackable_associations(auth_object = nil)
          []
        end
      RUBY
    end

    def sidebar_link
      <<~SLIM.gsub(/^/, '    ')
        li
          = link_to '#{human_name}', admin_#{plural_name}_path, class: 'block px-3 py-2 rounded text-sm text-gray-300 hover:bg-gray-700 hover:text-white transition-colors'
      SLIM
    end
  end
end
