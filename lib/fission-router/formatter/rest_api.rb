require 'fission-router'

module Fission
  module Router
    module Formatter

      # Format route based on rest api
      class RestApi < Fission::Formatter

        SOURCE = :rest_api
        DESTINATION = :router

        # Provide requested route for router based on url path from
        # github
        #
        # @param payload [Smash]
        def format(payload)
          unless(payload.get(:data, :router, :requested_route))
            if(route = payload.fetch(:data, :rest_api, :action))
              payload.set(:data, :router, :requested_route, route
            end
          end
        end

      end

    end
  end
end
