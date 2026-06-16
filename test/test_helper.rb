ENV["RAILS_ENV"] = "test"
require File.expand_path("dummy/config/environment", __dir__)
require "rails/test_help"
require "rails/generators/test_case"

require "generators/admin/install_generator"
require "generators/rails/admin/admin_generator"
