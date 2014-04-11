require 'fission/callback'

module Fission
  module Router
    class Router < Fission::Callback

      # NOTE: no custom `valid?` since all received messages on this
      # source are valid

      def execute(message)
        payload = unpack(message)
        unless(retrieve(payload, :data, :router, :route))
          route = discover_route(payload)
          if(route)
            payload[:data][:router][:route] = route
          else
            warn "Unable to discover routing information for payload: #{payload.inspect}"
            return job_completed(:router, payload, message) # short circuit
          end
        end
        payload[:data][:router][:route].shift while Array(payload[:complete]).include?(payload[:data][:router][:route].first)
        destination = payload[:data][:router][:route].first
        if(destination)
          info "Router is forwarding #{message} to next destination #{destination}"
          transmit(destination, payload)
          message.confirm!
        else
          info "Payload has completed custom routing. Marking #{message} as complete!"
          job_completed(:router, payload, message)
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
        key = retrieve(payload, :data, :router, :action)
        path = [:fission, :router] + (key ? [:routes, key] : [:route])
        route = Carnivore::Config.get(*path)
        unless(route)
          error "No route defined within configuration. Setting empty routing path!"
          route = []
        end
        route.dup
      end

    end
  end
end

Fission.register(:router, :router, Fission::Router::Router)
