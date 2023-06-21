ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../cl'

class ClTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup  

  end

  def teardown

  end

  def signed_in_session
    { 'rack.session' => { usnername: 'dev' } }
  end

  def test_sign_in_page
    get '/sign_in'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Please sign'
  end

  def test_sign_in
    post "/sign_in", username: 'dev', password: 'pass'
    
    assert_equal last_response.status, 302
    assert_includes last_response, 'dev has signed in.'

  end
end