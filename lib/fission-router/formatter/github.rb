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
              unless_filtered(route, payload) do
                payload.set(:data, :router, :requested_route, route)
              end
            end
          end
        end

        # Check for any github based filters applied to the route and
        # do not call block if filter does not allow
        #
        # @param route [String] requested route name
        # @param payload [Smash]
        # @return [Object] return value of block
        def unless_filtered(route, payload)
          allowed = events_filter(route, payload.get(:data, :github, :event)) &&
            ref_filter(route, payload.fetch(:data, :github, :ref,
              payload.get(:data, :github, payload.get(:data, :github, :event), :ref)
            ))
          if(allowed)
            yield if block_given?
          end
        end

        # Check if git reference is filtered and if so check if valid
        #
        # @param route [String] requested route name
        # @param ref [String] git reference
        # @return [TrueClass, FalseClass]
        def ref_filter(route, ref)
          allowed_refs = [config.fetch(:routes, route, :filters, :github, :refs, [])].flatten.compact
          allowed_refs.empty? || !!allowed_refs.detect{|allowed_ref| File.fnmatch?(allowed_ref, ref)}
        end

        # Check if github event is being filtered and if so check if
        # valid
        #
        # @param route [String] requested route name
        # @param github_event [String] github event
        # @return [TrueClass, FalseClass]
        def events_filter(route, github_event)
          allowed_events = [config.fetch(:routes, route, :filters, :github, :events, [])].flatten.compact
          allowed_events.empty? || allowed_events.include?(github_event)
        end

      end

    end
  end
end
