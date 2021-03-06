require 'omniauth-oauth'
require 'multi_json'
module OmniAuth
  module Strategies
    #taken from https://github.com/he9qi/omniauth_china/blob/55dac2d2a657d20711459f89dfeb802a8f06c81e/lib/omniauth_china/strategies/qzone.rb
    class Qzone < OmniAuth::Strategies::OAuth
      option :name, 'qzone'
      option :sign_in, true
      def initialize(*args)
        super
        options.client_options =  {
          :access_token_path => '/oauth/qzoneoauth_access_token',
          :authorize_path => '/oauth/qzoneoauth_authorize',
          :realm => 'OmniAuth',
          :request_token_path => '/oauth/qzoneoauth_request_token',
          :site => 'http://openapi.qzone.qq.com',
          :scheme             => :query_string,
          :http_method        => :get
        }
      end
      
      #HACK qzone is using a none-standard parameter oauth_overicode
      def callback_phase
        options.client_options[:access_token_path] = "/oauth/qzoneoauth_access_token?oauth_vericode=#{request['oauth_vericode'] }" if request['oauth_vericode']
        super
      end
     
      uid { access_token.params[:openid] }
      
      info do
        {
          'uid' => access_token.params[:openid],
          'nickname' => raw_info['nickname'],
          'name' =>  raw_info['nickname'],
          'image' => raw_info['figureurl'],
          'urls' => {
            'figureurl_1' =>raw_info['figureurl_1'],
            'figureurl_2' => raw_info['figureurl_2'],
          },
        }
      end
      extra do
        { :raw_info => raw_info }
      end

      def raw_info
        @raw_info ||= MultiJson.decode(access_token.get("/user/get_user_info?format=json&openid=#{access_token.params[:openid]}").body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end

      def request_phase
        options[:authorize_params].merge!({:oauth_consumer_key=>options.consumer_key})
        super
      end
    end
  end
end
