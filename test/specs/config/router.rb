Configuration.new do
  fission do
    router do
      allow_user_routes true
      custom_routes.bar.path :bar

      routes do
        default.path :foo
      end
    end

    sources do
      router.type 'actor'
      validator.type 'actor'
      foo.type 'actor'
      bar.type 'actor'
      test.type 'spec'
    end

    workers do
      router 1
      validator 1
      foo 1
      bar 1
    end

    loaders do
      sources ['carnivore-actor']
      workers ['fission-router/router']
    end
  end
end
