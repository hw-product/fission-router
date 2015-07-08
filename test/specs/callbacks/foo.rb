require 'fission/callback'

module Fission
  class Foo < Fission::Callback
    def setup(*args)
      @foo = 'foo'
    end

    def valid?(message)
      true
    end

    def execute(message)
      failure_wrap(message) do |payload|
        calls = payload.fetch(:services_calls, [])
        payload.set(:services_calls, (calls + [:foo]))
        job_completed(:foo, payload, message)
      end
    end
  end
end

Fission.register(:foo, Fission::Foo)
