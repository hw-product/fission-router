require 'fission/callback'

module Fission
  module Router
    class Router < Fission::Callback

      # Keys restricted from custom services
      RESTRICTED_DATA_KEYS = [:account, :router]

      # NOTE: no custom `valid?` since all received messages on this
      # source are valid

      # Route payloads
      #
      # @param message [Carnivore::Message]
      def execute(message)
        failure_wrap(message) do |payload|
          if(payload.get(:error))
            message.confirm!
            payload.set(:frozen, true)
            process_error(message, payload)
          else
            if(payload.get(:data, :router, :restore))
              r_payload = restore_persisted_payload(payload)
              route_payload(message, r_payload)
            else
              if(!payload.get(:data, :account) && (config[:allow_user_routes] || config[:allow_user_destinations]))
                transmit(:validator, payload)
                message.confirm!
              else
                set_route(payload)
                route_payload(message, payload)
              end
            end
          end
          async.store_payload(payload)
        end
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
        unless(payload.get(:data, :router, :action))
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
          unless(custom_destination(destination, payload, message))
            info "Router is forwarding #{message} to next destination #{destination}"
            transmit(destination, payload)
          end
          message.confirm!
        else
          info "Payload has completed custom routing. Marking #{message} as complete!"
          job_completed(:router, payload, message)
          process_complete(message, payload)
        end
      end

      # Check configuration for custom destination matching name
      # and transmit to endpoint if found
      #
      # @param destination [Symbol, String]
      # @param payload [Smash]
      # @return [TrueClass, FalseClass]
      def custom_destination(destination, payload, message)
        if(config.get(:allow_user_destinations) && config.get(:custom_services, destination))
          warn "Custom endpoint detected and allowed for message #{message} named #{destination}"
          endpoint = config.get(:custom_services, destination)
          debug "Router is forwarding #{message} to custom destination #{destination}"
          send_data = payload.get(:data)
          # Remove account information from payload prior to send
          RESTRICTED_DATA_KEYS.each do |key|
            send_data.delete(key)
          end
          send_data.set(:router, :restore, true)
          custom_payload = new_payload(destination, send_data)
          asset_store.put("router-persist/#{custom_payload[:message_id]}", MultiJson.dump(payload))
          debug "Persisting payload data to asset store at: router-persist/#{custom_payload[:message_id]}"
          result = HTTP.post(endpoint, :json => custom_payload)
          unless(result.status_code == 200)
            abort "Custom service request failed (#{destination}): Status: #{result.status_code} - #{result.body.to_s}"
          end
          true
        else
          false
        end
      end

      # Restore payload and merge any new data from custom service
      #
      # @param payload [Smash] received payload
      # @return [Smash] restored payload
      def restore_payload(payload)
        if(config.get(:allow_user_destinations))
          begin
            r_payload = asset_store.get("router-persist/#{payload[:message_id]}")
            r_payload = MultiJson.load(r_payload).to_smash
            p_data = payload.get(:data)
            RESTRICTED_DATA_KEYS.each do |key|
              p_data.delete(key)
            end
            r_payload[:data].deep_merge!(p_data)
            r_payload
          rescue => e
            abort "Failed to restore payload for processing! Received payload ID: #{payload[:message_id]} - #{e.class}: #{e}"
          end
        else
          abort 'Restore style payload received but user destinations are forbidden via configuration!'
        end
      end

      # Determine route for given payload
      #
      # @param payload [Smash]
      # @return [Smash] routing information
      def discover_route(payload)
        route = user_defined_route(payload)
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
      def user_defined_route(payload)
        if(config[:allow_user_routes])
          if(route = payload.get(:data, :router, :requested_route))
            if(route_path = config.get(:custom_routes, route))
              debug "User defined route detected. Applying custom route (#{route})!"
              Smash.new(
                :name => route,
                :path => route_path
              )
            end
          end
        end
      end

      # Determine route for given payload from configuration
      #
      # @param payload [Smash]
      # @return [Smash, NilClass] route information
      def config_defined_route(payload)
        route = payload.fetch(:data, :router, :requested_route,
          Carnivore::Config.get(:fission, :router, :routes, 'default')
        )
        if(route.is_a?(String) || route.is_a?(Symbol))
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
