Configuration.new do
  fission do
    router do
      routes do
        default.complete 'test'
      end
    end

    sources do
      router.type 'actor'
      test.type 'spec'
    end

    workers.router 1

    loaders do
      sources ['carnivore-actor']
      workers ['fission-router/router']
    end
  end
end
