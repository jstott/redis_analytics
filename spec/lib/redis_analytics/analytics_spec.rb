require 'spec_helper'

describe Rack::RedisAnalytics::Analytics do

  subject(:app) {
    Rack::Builder.app do
      use Rack::RedisAnalytics::Analytics
      run Proc.new { |env| [200, {'Content-Type' => 'text/html'}, "Hello!"] }
    end
  }

  before(:each) do
    clear_cookies
  end

  # Spec for Cookies
  context "when a user makes 2 visits and the visit cookie and returning user cookie are not expired" do
    def cookie
      last_response.original_headers['Set-Cookie']
    end
    it "should count as the same visit in the cookie" do
      t1 = Time.now
      Time.stubs(:now).returns(t1)
      get '/'
      cookie.should match("#{Rack::RedisAnalytics.visit_cookie_name}=1.1.#{t1.to_i}.#{t1.to_i}")
      cookie.should match("#{Rack::RedisAnalytics.returning_user_cookie_name}=1.#{t1.to_i}.#{t1.to_i}")
      t2 = t1 + 5 # just adding 5 seconds
      Time.stubs(:now).returns(t2)
      get '/'
      cookie.should match("#{Rack::RedisAnalytics.visit_cookie_name}=1.1.#{t1.to_i}.#{t2.to_i}")
      cookie.should match("#{Rack::RedisAnalytics.returning_user_cookie_name}=1.#{t1.to_i}.#{t2.to_i}")
    end
  end
  
  context "when a user makes 2 visits, but visit cookie and returning user cookie are both non-existent" do
    def cookie
      last_response.original_headers['Set-Cookie']
    end
    it "should count as a separate and new visit in the cookie" do
      t1 = Time.now
      Time.stubs(:now).returns(t1)
      get '/'
      cookie.should match("#{Rack::RedisAnalytics.visit_cookie_name}=1.1.#{t1.to_i}.#{t1.to_i}")
      cookie.should match("#{Rack::RedisAnalytics.returning_user_cookie_name}=1.#{t1.to_i}.#{t1.to_i}")
      clear_cookies

      t2 = t1 + 5 # just adding 5 seconds
      Time.stubs(:now).returns(t2)
      get '/'
      cookie.should match("#{Rack::RedisAnalytics.visit_cookie_name}=2.2.#{t2.to_i}.#{t2.to_i}")
      cookie.should match("#{Rack::RedisAnalytics.returning_user_cookie_name}=2.#{t2.to_i}.#{t2.to_i}")
    end
  end

  context "when a user makes 2 visits, and visit cookie is expired but the returning user cookie exists" do
    it "should count as a separate visit but not a new visit"
  end

end
