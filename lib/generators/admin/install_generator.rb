module Admin
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def create_base_controller
      template 'application_controller.rb.tt',
               'app/controllers/admin/application_controller.rb'
    end

    def create_csv_concern
      template 'csv_exportable.rb.tt',
               'app/controllers/concerns/csv_exportable.rb'
    end

    def create_dashboard
      template 'dashboard_controller.rb.tt',
               'app/controllers/admin/dashboard_controller.rb'
      template 'admin/dashboard/index.html.slim.tt',
               'app/views/admin/dashboard/index.html.slim'
    end

    def create_layout
      template 'layouts/admin.html.slim.tt',
               'app/views/layouts/admin.html.slim'
    end

    def create_shared_views
      template 'admin/shared/_flash.html.slim.tt',
               'app/views/admin/shared/_flash.html.slim'
      template 'admin/shared/_sidebar.html.slim.tt',
               'app/views/admin/shared/_sidebar.html.slim'
      template 'admin/shared/_pagination.html.slim.tt',
               'app/views/admin/shared/_pagination.html.slim'
    end

    def create_locale_files
      template 'locales/admin.ja.yml.tt', 'config/locales/admin.ja.yml'
      template 'locales/admin.en.yml.tt', 'config/locales/admin.en.yml'
    end

    def set_default_locale
      inject_into_file 'config/application.rb',
                       "    config.i18n.default_locale = :ja\n\n",
                       after: "class Application < Rails::Application\n"
    end

    def create_admin_routes_file
      create_file 'config/routes/admin.rb',
                  "namespace :admin do\n  root to: 'dashboard#index'\nend\n"
    end

    def inject_draw_admin
      route 'draw :admin'
    end

    def add_csv_gem
      gem 'csv'
    end
  end
end
