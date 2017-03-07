# frozen_string_literal: true

# Our Rack application to be executed by rackup
class HelloWorld < Roda
  plugin :default_headers, 'Content-Type'=>'text/html; charset=utf-8'
  plugin :default_headers, 'Server'=>SERVER_STRING if SERVER_STRING
  plugin :hooks
  plugin :json
  plugin :render, :escape=>:erubi, :layout_opts=>{ :cache_key=>'default_layout' }
  plugin :static_routing

  def bounded_queries
    queries = request['queries'].to_i
    return QUERIES_MIN if queries < QUERIES_MIN
    return QUERIES_MAX if queries > QUERIES_MAX
    queries
  end

  # Return a random number between 1 and MAX_PK
  def rand1
    Random.rand(MAX_PK).succ
  end

  after do
    response['Date'] = Time.now.httpdate
  end

  # Test type 1: JSON serialization
  static_get '/json' do
    { :message=>'Hello, World!' }
  end

  # Test type 2: Single database query
  static_get '/db' do
    World.with_pk(rand1).values
  end

  # Test type 3: Multiple database queries
  static_get '/queries' do
    Array.new(bounded_queries) { World.with_pk(rand1).values }
  end

  # Test type 4: Fortunes
  static_get '/fortunes' do
    @fortunes = Fortune.all
    @fortunes << Fortune.new(
      :id=>0,
      :message=>'Additional fortune added at request time.'
    )
    @fortunes.sort_by!(&:message)

    view :fortunes
  end

  # Test type 5: Database updates
  static_get '/updates' do
    Array.new(bounded_queries) do
      world = World.with_pk(rand1)
      world.update(:randomnumber=>rand1)
      world.values
    end
  end

  # Test type 6: Plaintext
  static_get '/plaintext' do
    response['Content-Type'] = 'text/plain'

    'Hello, World!'
  end

  # Even though we don't have any non-static routes, this is still required.
  route { |_| }
end