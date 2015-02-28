require 'fission-router'

module Fission
  module Router
    module Formatter

      # Format route based on github
      class Github < Fission::Formatter

        SOURCE = :github
        DESTINATION = :router

        # Provide requested route for router based on url path from
        # github
        #
        # @param payload [Smash]
        def format(payload)
          unless(payload.get(:data, :router, :requested_route))
            if(path = payload.get(:data, :github, :url_path))
              payload.set(:data, :router, :requested_route, path.split('/').last)
            end
          end
        end

      end

    end
  end
end
