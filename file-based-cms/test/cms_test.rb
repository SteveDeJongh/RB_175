ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_pages
    get "/changes.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-type"]
    assert_includes last_response.body, "chaaaaanges"
  end

  def test_document_not_found
    get "/notafile.ext" # Attempt to access a nonexistent file

    assert_equal 302, last_response.status # Assert the the user was redirected.

    get last_response["Location"] # Request the page that the user was redirected to

    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.ext does not exist"

    get "/" # Reload the page
    refute_includes last_response.body, "notafile.ext does not exist" # Make sure the error message only appears once.
  end

  def test_markdown
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end
end
