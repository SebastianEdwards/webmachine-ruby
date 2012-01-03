require 'rack/request'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'

module Webmachine
  module Adapters
    # A minimal "shim" adapter to allow Webmachine to interface with Rack. The
    # intention here is to allow Webmachine to run under Rack-compatible
    # web-servers, like unicorn and pow, and is not intended to allow Webmachine
    # to be "plugged in" to an existing Rack app as middleware.
    #
    # To use this adapter, create a config.ru file and populate it like so:
    #
    #     require 'webmachine/adapters/rack'
    #
    #     # put your own Webmachine resources in another file:
    #     require 'my/resources'
    #
    #     run Webmachine::Adapters::Rack.new
    #
    # Servers like pow and unicorn will read config.ru by default and it should
    # all "just work".
    class Rack
      def initialize(configuration = Webmachine.configuration, dispatcher = Webmachine::Dispatcher)
        @configuration = configuration
        @dispatcher    = dispatcher
      end

      # Handles a Rack-based request.
      # @param [Hash] env the Rack environment
      def call(env)
        headers = Webmachine::Headers.from_cgi(env)

        rack_req = ::Rack::Request.new env
        request = Webmachine::Request.new(rack_req.request_method,
                                          URI.parse(rack_req.url),
                                          headers,
                                          rack_req.body)

        response = Webmachine::Response.new
        @dispatcher.dispatch(request, response)

        response.headers['Server'] = [Webmachine::SERVER_STRING, "Rack/#{::Rack.version}"].join(" ")

        body = response.body.respond_to?(:call) ? response.body.call : response.body
        body = body.is_a?(String) ? [ body ] : body

        [response.code.to_i, response.headers, body || []]
      end
    end
  end
end
