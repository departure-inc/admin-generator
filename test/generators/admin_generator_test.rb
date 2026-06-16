require "test_helper"

class AdminGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::AdminGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  # ジェネレーターが inject する先のファイルを事前配置
  setup do
    FileUtils.mkdir_p File.join(destination_root, "config/routes")
    File.write File.join(destination_root, "config/routes/admin.rb"),
               "namespace :admin do\nend\n"

    FileUtils.mkdir_p File.join(destination_root, "app/views/admin/shared")
    File.write File.join(destination_root, "app/views/admin/shared/_sidebar.html.slim"),
               "ul\n  / ナビゲーションリンクは rails g admin <ModelName> で自動追加されます\n"

    FileUtils.mkdir_p File.join(destination_root, "app/models")
    File.write File.join(destination_root, "app/models/article.rb"),
               "class Article < ApplicationRecord\nend\n"
  end

  # --- コントローラー ---

  test "creates controller with correct class name" do
    run_generator %w[Article]
    assert_file "app/controllers/admin/articles_controller.rb" do |content|
      assert_match "class Admin::ArticlesController < Admin::ApplicationController", content
    end
  end

  test "controller includes CsvExportable" do
    run_generator %w[Article]
    assert_file "app/controllers/admin/articles_controller.rb" do |content|
      assert_match "include CsvExportable", content
    end
  end

  test "controller has all CRUD actions" do
    run_generator %w[Article]
    assert_file "app/controllers/admin/articles_controller.rb" do |content|
      %w[index show new edit create update destroy].each do |action|
        assert_match "def #{action}", content
      end
    end
  end

  test "controller index uses ransack and kaminari" do
    run_generator %w[Article]
    assert_file "app/controllers/admin/articles_controller.rb" do |content|
      assert_match "Article.ransack(params[:q])", content
      assert_match ".page(params[:page])", content
      assert_match "format.csv", content
      assert_match "export_csv", content
      assert_match 'filename: "articles-#{Time.zone.today}.csv"', content
    end
  end

  test "strong params excludes id and timestamps" do
    run_generator %w[Article]
    assert_file "app/controllers/admin/articles_controller.rb" do |content|
      assert_no_match(/:id/, content.match(/def article_params.*end/m).to_s)
      assert_no_match(/:created_at/, content.match(/def article_params.*end/m).to_s)
      assert_no_match(/:updated_at/, content.match(/def article_params.*end/m).to_s)
    end
  end

  test "strong params includes business columns" do
    run_generator %w[Article]
    assert_file "app/controllers/admin/articles_controller.rb" do |content|
      assert_match ":title", content.match(/def article_params.*end/m).to_s
      assert_match ":body", content.match(/def article_params.*end/m).to_s
      assert_match ":published", content.match(/def article_params.*end/m).to_s
    end
  end

  # --- ビュー: index ---

  test "creates index view with all column headers" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/index.html.slim" do |content|
      %w[id title body published published_at view_count created_at updated_at].each do |col|
        assert_match col, content
      end
    end
  end

  test "index view total_count interpolation is not escaped" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/index.html.slim" do |content|
      assert_match '"Article: #{@articles.total_count}件"', content
      assert_no_match '\#{@articles.total_count}', content
    end
  end

  test "index view has new link, CSV download, search form, pagination" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/index.html.slim" do |content|
      assert_match "new_admin_article_path", content
      assert_match "format: :csv", content
      assert_match "render 'search_form'", content
      assert_match "render 'admin/shared/pagination'", content
    end
  end

  test "index view has show/edit/delete links per row" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/index.html.slim" do |content|
      assert_match "admin_article_path(article)", content
      assert_match "edit_admin_article_path(article)", content
      assert_match "turbo_method: :delete", content
    end
  end

  # --- ビュー: show ---

  test "creates show view with dl/dt/dd format" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/show.html.slim" do |content|
      assert_match "dl", content
      assert_match "dt", content
      assert_match "dd", content
    end
  end

  test "show view lists all columns" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/show.html.slim" do |content|
      %w[title body published published_at view_count].each do |col|
        assert_match col, content
      end
    end
  end

  # --- ビュー: form ---

  test "creates form view" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_form.html.slim" do |content|
      assert_match "form_with model: [:admin, article]", content
    end
  end

  test "form error count interpolation is not escaped" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_form.html.slim" do |content|
      assert_match '（#{article.errors.count}件のエラー）"', content
      assert_no_match '\#{article.errors.count}', content
    end
  end

  test "form uses text_field for string columns" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_form.html.slim" do |content|
      assert_match "f.text_field :title", content
    end
  end

  test "form uses text_area for text columns" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_form.html.slim" do |content|
      assert_match "f.text_area :body", content
    end
  end

  test "form uses check_box for boolean columns" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_form.html.slim" do |content|
      assert_match "f.check_box :published", content
    end
  end

  test "form uses datetime_local_field for datetime columns" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_form.html.slim" do |content|
      assert_match "f.datetime_local_field :published_at", content
    end
  end

  test "form uses number_field for integer columns" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_form.html.slim" do |content|
      assert_match "f.number_field :view_count", content
    end
  end

  test "form excludes id and timestamps" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_form.html.slim" do |content|
      assert_no_match "f.text_field :id", content
      assert_no_match ":created_at", content
      assert_no_match ":updated_at", content
    end
  end

  # --- ビュー: search_form ---

  test "creates freeword search form combining string/text columns" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_search_form.html.slim" do |content|
      assert_match(/f\.search_field :(title_or_body|body_or_title)_cont/, content)
    end
  end

  test "search form excludes non-string columns from freeword attribute" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/_search_form.html.slim" do |content|
      assert_no_match "published", content
      assert_no_match "view_count", content
    end
  end

  # --- new / edit ---

  test "creates new and edit views" do
    run_generator %w[Article]
    assert_file "app/views/admin/articles/new.html.slim" do |content|
      assert_match "render 'form'", content
    end
    assert_file "app/views/admin/articles/edit.html.slim" do |content|
      assert_match "render 'form'", content
    end
  end

  # --- routes inject ---

  test "injects resources into namespace :admin block" do
    run_generator %w[Article]
    assert_file "config/routes/admin.rb" do |content|
      assert_match "resources :articles", content
    end
  end

  # --- sidebar inject ---

  test "injects nav link into sidebar" do
    run_generator %w[Article]
    assert_file "app/views/admin/shared/_sidebar.html.slim" do |content|
      assert_match "admin_articles_path", content
      assert_match "Article", content
    end
  end

  # --- ransack allowlist inject ---

  test "injects ransackable_attributes and ransackable_associations into model" do
    run_generator %w[Article]
    assert_file "app/models/article.rb" do |content|
      assert_match "def self.ransackable_attributes(auth_object = nil)", content
      assert_match(/%w\(title body\)|%w\(body title\)/, content)
      assert_match "def self.ransackable_associations(auth_object = nil)", content
    end
  end
end
