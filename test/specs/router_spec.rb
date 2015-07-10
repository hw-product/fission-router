require 'fission-data'
require 'fission-router'
require 'fission-validator'

require_relative 'callbacks/foo'
require_relative 'callbacks/bar'
require 'pry'

DEFAULT_SECRET = 'foo'

module Fission::Utils::Cipher
  def self.decrypt(msg, h)
    {
      :router => {
        :custom_routes => {
          :bar => { :configs => [] }
        }
      }
    }.to_json
  end
end

class Fission::Router::Router
  def app_config
    Smash.new
  end
  def apply_route_payload_filters!(filters, payload)
    true
  end
end

class Fission::Validator::Github < Fission::Callback
  def execute(message)
    failure_wrap(message) do |payload|
      h = {
        :id   => 1,
        :name => 'foo',
        :config => "{}"
      }
      payload.set(:data, :account, h.to_smash)
      job_completed(:validator, payload, message)
    end
  end
end

describe Fission::Router::Router do

  before do
    @runner = run_setup(:router)
    track_execution(Fission::Router::Router)
  end

  after { @runner.terminate }

  let(:actor) { Carnivore::Supervisor.supervisor[:router] }

  it 'routes to default path with no route provided' do
    result = transmit_and_wait(actor, transmit_and_wait(actor, payload))
    callback_executed?(result).must_equal true
    result[:complete].must_include('foo')
  end

  it 'redirects to route specified in complete config' do
    h = {
      :router => {
        :requested_route => :baz
      }
    }
    r0 = transmit_and_wait(actor, payload(h))
    r1 = transmit_and_wait(actor, r0)
    r1[:complete].must_include('foo')
  end

  it 'routes to all services specified in the payload' do
    h = {
      :router => {
        :action => 'default',
        :route  => [:foo, :bar]
      }
    }
    r0 = transmit_and_wait(actor, payload(h))
    r1 = transmit_and_wait(actor, r0)
    r2 = transmit_and_wait(actor, r1)

    ['foo', 'bar'].all? { |route| r2[:complete].must_include(route) }
  end

  it 'routes to all services specified in requested path' do
    Carnivore::Config.delete(:allow_user_routes)
    h = {
      :router => {
        :requested_route => { :path => [:foo, :bar] }
      }
    }

    r0 = transmit_and_wait(actor, payload(h))
    r1 = transmit_and_wait(actor, r0)
    r2 = transmit_and_wait(actor, r1)
    ['foo', 'bar'].all? { |route| r2[:complete].must_include(route) }
  end

  it 'processes user defined route over config defined one' do
    h = {
      :router => {
        :requested_route => :bar
      }
    }
    r0 = transmit_and_wait(actor, payload(h))
    r1 = transmit_and_wait(actor, r0)
    r1[:complete].must_include('bar')
  end

  private

  def payload(opts = {})
    h = { :validator => { :github => { :repository => 'foo' }}}
    Jackal::Utils.new_payload(:test, opts.merge(h))
  end
end
