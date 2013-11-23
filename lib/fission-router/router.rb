require 'fission/callback'

module Fission
  module Router
    class Router < Fission::Callback

      # NOTE: no custom `valid?` since all received messages on this
      # source are valid

      def execute(message)
        payload = unpack(message)
        unless(payload[:data][:router])
          route = discover_route(payload)
          if(route)
            payload[:data][:router] = route
          else
            warn "Unable to discovery routing information for payload: #{payload.inspect}"
            return completed_job(:router, payload, message) # short circuit
          end
        end
        destination = payload[:data][:router].shift
        if(destination)
          info "Router is forwarding #{message} to next destination #{destination}"
          payload[:job] = destination
          forward(payload)
        else
          info "Payload has completed custom routing. Marking #{message} as complete!"
          completed_job(:router, payload, message)
        end
      end

      # TODO: This should have fission-data-models attached and be
      # able to do rule based lookups on state of data. Will need to
      # have a user validator to get proper user population.
      #
      # This method should just call to specialized methods based on configuration
      def discover_route(payload)
        case Carnivore::Config.get(:fission, :router, :behavior)
        when 'user'
          user_defined_routing(payload)
        when 'config'
          config_defined_routing(payload)
        else
          error "Unknown routing behavior encountered. Setting empty routing path! (behavior: #{Carnivore::Config.get(:fission, :router, :behavior)})"
          []
        end
      end

      def user_defined_routing(payload)
        abort NotImplemented.new('User defined routing not yet supported')
      end

      def config_defined_routing(payload)
        route = Carnivore::Config.get(:fission, :router, :route)
        unless(route)
          error "No route defined within configuration. Setting empty routing path!"
          route = []
        end
        route
      end

    end
  end
end

Fission.register(:router, :router, Fission::Router::Router)
