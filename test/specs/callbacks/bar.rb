require 'fission/callback'

module Fission
  class Bar < Fission::Callback
    def setup(*args)
      @bar = 'bar'
    end

    def valid?(message)
      true
    end

    def execute(message)
      failure_wrap(message) do |payload|
        calls = payload.fetch(:services_calls, [])
        payload.set(:services_calls, (calls + [:bar]))
        job_completed(:bar, payload, message)
      end
    end
  end
end

Fission.register(:bar, Fission::Bar)
