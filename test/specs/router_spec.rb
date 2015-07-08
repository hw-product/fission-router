require 'fission-router'
require_relative 'callbacks/foo'
require_relative 'callbacks/bar'
require 'pry'

DEFAULT_SECRET = 'foo'

describe Fission::Router::Router do

  before do
    @runner = run_setup(:router)
    track_execution(Fission::Router::Router)
  end

  after { @runner.terminate }

  let(:actor) { Carnivore::Supervisor.supervisor[:router] }

  it 'routes to default path with no route provided' do
    result = transmit_and_wait(actor, payload)
    callback_executed?(result).must_equal true
    result[:complete].must_include('foo')
  end

  it 'routes to all services specified in the payload' do
    h = { :router => { :action => 'default',
                       :route  => [:foo, :bar] }}

    r1 = transmit_and_wait(actor, payload(h))
    r2 = transmit_and_wait(actor, r1)
    ['foo', 'bar'].all? { |route| r2[:complete].must_include(route) }
  end

  private

  def payload(opts = {})
    Jackal::Utils.new_payload(:test, opts)
  end
end
