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
              route = path.split('/').last
              unless_filtered(route, payload.get(:data, :github, :event) do
                payload.set(:data, :router, :requested_route, route)
              end
            end
          end
        end

        # Check if event filtering is enabled for the requested path
        # and do not call given block if event is filtered
        #
        # @param route [String] requested route name
        # @param github_event [String] event name
        # @return [Object] return value of block
        def unless_filtered(route, github_event)
          allowed_events = [config.fetch(:routes, route, :filters, :github, :events, [])].flatten.compact
          if(allowed_events.empty? || allowed_events.include?(github_event))
            yield if block_given?
          end
        end

      end

    end
  end
end
