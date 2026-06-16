require "test_helper"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Admin::InstallGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  # routes.rb と Gemfile をテスト前に配置
  setup do
    FileUtils.mkdir_p File.join(destination_root, "config")
    File.write File.join(destination_root, "config/routes.rb"),
               "Rails.application.routes.draw do\nend\n"

    File.write File.join(destination_root, "Gemfile"),
               "source \"https://rubygems.org\"\ngem \"rails\"\n"

    File.write File.join(destination_root, "config/application.rb"),
               "module Dummy\n  class Application < Rails::Application\n  end\nend\n"
  end

  test "creates Admin::ApplicationController" do
    run_generator
    assert_file "app/controllers/admin/application_controller.rb" do |content|
      assert_match "class Admin::ApplicationController < ApplicationController", content
      assert_match "layout 'admin'", content
      assert_match "helper_method :current_admin", content
      assert_match "Current.administrator", content
    end
  end

  test "creates CsvExportable concern" do
    run_generator
    assert_file "app/controllers/concerns/csv_exportable.rb" do |content|
      assert_match "module CsvExportable", content
      assert_match "extend ActiveSupport::Concern", content
      assert_match "def export_csv", content
      assert_match "CSV.generate", content
      assert_match "send_data", content
    end
  end

  test "creates admin layout" do
    run_generator
    assert_file "app/views/layouts/admin.html.slim" do |content|
      assert_match "render 'admin/shared/sidebar'", content
      assert_match "render 'admin/shared/flash'", content
      assert_match "session_path", content
    end
  end

  test "creates flash partial" do
    run_generator
    assert_file "app/views/admin/shared/_flash.html.slim" do |content|
      assert_match "flash.each", content
      assert_match "alert", content
    end
  end

  test "creates sidebar partial with inject marker" do
    run_generator
    assert_file "app/views/admin/shared/_sidebar.html.slim" do |content|
      assert_match "ナビゲーションリンクは rails g admin <ModelName> で自動追加されます", content
      assert_match "current_admin", content
    end
  end

  test "creates pagination partial" do
    run_generator
    assert_file "app/views/admin/shared/_pagination.html.slim" do |content|
      assert_match "paginate collection", content
    end
  end

  test "creates dashboard controller and view" do
    run_generator
    assert_file "app/controllers/admin/dashboard_controller.rb" do |content|
      assert_match "class Admin::DashboardController < Admin::ApplicationController", content
      assert_match "def index", content
    end
    assert_file "app/views/admin/dashboard/index.html.slim" do |content|
      assert_match "dashboard", content
    end
  end

  test "creates config/routes/admin.rb with namespace block and dashboard root" do
    run_generator
    assert_file "config/routes/admin.rb" do |content|
      assert_match "namespace :admin do", content
      assert_match "root to: 'dashboard#index'", content
    end
  end

  test "injects draw :admin into routes.rb" do
    run_generator
    assert_file "config/routes.rb" do |content|
      assert_match "draw :admin", content
    end
  end

  test "creates ja and en locale files" do
    run_generator
    assert_file "config/locales/admin.ja.yml" do |content|
      assert_match "ja:", content
      assert_match "login_required", content
      assert_match "%{model}を作成しました。", content
    end
    assert_file "config/locales/admin.en.yml" do |content|
      assert_match "en:", content
      assert_match "login_required", content
      assert_match "%{model} was created.", content
    end
  end

  test "sets default locale to ja in config/application.rb" do
    run_generator
    assert_file "config/application.rb" do |content|
      assert_match "config.i18n.default_locale = :ja", content
    end
  end

  test "adds csv gem to Gemfile" do
    run_generator
    assert_file "Gemfile" do |content|
      assert_match "gem \"csv\"", content
    end
  end
end
