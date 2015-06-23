require 'fission-router'
require 'pry'

describe Fission::Router::Router do

  before do
    @runner = run_setup(:router)
    @method_calls = track_method_calls(Fission::Router::Router)
  end

  after { @runner.terminate }

  let(:actor) { Carnivore::Supervisor.supervisor[:router] }


  it 'executes with empty payload and sets empty route' do
    result = transmit_and_wait(actor, payload)
    assert_method_calls(:execute, :discover_route, :set_route, :route_payload)

    expected = { :route => [], :action => 'default' }.to_smash
    result[:data][:router].must_equal(expected)
  end

  private

  def assert_method_calls(*meths)
    meths.each { |meth| @method_calls.must_include(meth) }
  end

  def payload(opts = {})
    h = { :data => opts }
    Jackal::Utils.new_payload(:test, h)
  end
end
