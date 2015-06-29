require 'fission-router'
require 'pry'

describe Fission::Router::Router do

  before do
    @runner = run_setup(:router)
    track_execution(Fission::Router::Router)
  end

  after { @runner.terminate }

  let(:actor) { Carnivore::Supervisor.supervisor[:router] }


  it 'executes with empty payload and sets empty route' do
    result = transmit_and_wait(actor, payload)
    callback_executed?(result).must_equal true
    
    expected = { :route => [], :action => 'default' }.to_smash
    result[:data][:router].must_equal(expected)
  end

  private

  def payload(opts = {})
    h = { :data => opts }
    Jackal::Utils.new_payload(:test, h)
  end
end
