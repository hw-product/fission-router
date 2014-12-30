require 'fission/callback'

module Fission
  module Router
    class Router < Fission::Callback

      # NOTE: no custom `valid?` since all received messages on this
      # source are valid

      # Route payloads
      #
      # @param message [Carnivore::Message]
      def execute(message)
        payload = unpack(message)
        if(payload.get(:error))
          process_error(message, payload)
        else
          set_route(payload)
          route_payload(message, payload)
        end
        async.store_payload(payload)
      end

      # If payload is in error state, send
      # to custom error handler if provided
      #
      # @param message [Carnivore::Message]
      # @param payload [Smash]
      # @return [Smash] payload
      def process_error(message, payload)
        [discover_route(payload)[:error]].flatten.compact.each do |dest|
          warn "Error routing for message (#{message}) -> #{dest}"
          transmit(dest, payload)
        end
      end

      # If payload is in complete state, send
      # to custom complete handler if provided
      #
      # @param message [Carnivore::Message]
      # @param payload [Smash]
      # @return [Smash] payload
      def process_complete(message, payload)
        [discover_route(payload)[:complete]].flatten.compact.each do |dest|
          info "Complete routing for message (#{message}) -> #{dest}"
          transmit(dest, payload)
        end
      end

      # Discover route and set within payload
      #
      # @param payload [Smash]
      # @return [Smash] payload
      def set_route(payload)
        unless(payload.get(:data, :router, :route))
          route_info = discover_route(payload)
          payload.set(:data, :router, :route,
            [route_info[:path]].flatten.compact
          )
          payload.set(:data, :router, :action, route_info[:name])
        end
        payload
      end

      # Route payload to defined path
      #
      # @param message [Carnivore::Message]
      # @param payload [Smash]
      # @return [Smash] payload
      def route_payload(message, payload)
        payload_complete = [payload[:complete]].flatten.compact
        while(payload_complete.include?(payload[:data][:router][:route].first))
          payload[:data][:router][:route].shift
        end
        destination = payload[:data][:router][:route].first
        if(destination)
          info "Router is forwarding #{message} to next destination #{destination}"
          transmit(destination, payload)
          message.confirm!
        else
          info "Payload has completed custom routing. Marking #{message} as complete!"
          job_completed(:router, payload, message)
          process_complete(message, payload)
        end
      end

      # Determine route for given payload
      #
      # @param payload [Smash]
      # @return [Smash] routing information
      def discover_route(payload)
        if(enabled?(:data))
          route = user_defined_route(payload)
        end
        unless(route)
          route = config_defined_route(payload)
        end
        route || Smash.new
      end

      # Determine route for given payload from stored
      # data route provided by user
      #
      # @param payload [Smash]
      # @return [Smash, NilClass] route information
      # @todo the implementation!
      def user_defined_route(payload)
        nil
      end

      # Determine route for given payload from configuration
      #
      # @param payload [Smash]
      # @return [Smash, NilClass] route information
      def config_defined_route(payload)
        route = payload.fetch(:data, :rest_api, :action,
          Carnivore::Config.get(:fission, :router, :routes, 'default')
        )
        if(route.is_a?(String))
          action = route
          route = Carnivore::Config.get(:fission, :router, :routes, route)
        else
          action = 'default'
        end
        if(route)
          route.merge!(
            Smash.new(
              :name => action
            )
          )
        end
        route
      end

    end
  end
end

Fission.register(:router, :router, Fission::Router::Router)
