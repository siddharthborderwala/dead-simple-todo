require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/cross_origin'
require 'json'
require 'json-schema'

set :database, {adapter: 'sqlite3', database: 'db/todo.sqlite3'}
set :views, File.join(File.dirname(__FILE__), 'views')

class Todo < ActiveRecord::Base
end

class User < ActiveRecord::Base
  has_secure_password
end

configure do
  enable :cross_origin, :sessions
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

options "*" do
  response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  200
end

createTodoValidator = {
  'type' => 'object',
  'required' => ['title', 'completed'],
  'properties' => {
    'title' => {
      'type': 'string'
    },
    'completed' => {
      'type': 'boolean'
    }
  },
  'additionalProperties' => false
}

updateTodoValidator = {
  'type' => 'object',
  'properties' => {
    'title' => {
      'type' => 'string'
    },
    'completed' => {
      'type' => 'boolean'
    }
  },
  'additionalProperties' => false
}

post '/login' do
  user = User.find_by(username: params[:username])

  if user && user.authenticate(params[:password])
    session[:user_id] = user.id
    redirect '/todos'
  else
    "Login failed"
  end
end

get '/' do
  @todos = Todo.all
  erb :index
end

post '/todos/:id/completed' do
  id = params['id']
  todo = Todo.find(id)

  if todo
    Todo.update(id, completed: !todo.completed)
    redirect '/'
  else
    status 404
    return
  end
end

post '/todos' do
  title = params['title']

  todo = Todo.new(title: title, completed: false)

  if todo.save
    redirect '/'
  else
    status 500
    return
  end
end

get '/todos' do
  content_type :json

  Todo.all.to_json
end

# post '/todos' do
#   content_type :json

#   data = JSON.parse(request.body.read)
#   todo_data = data['todo']

#   begin
#     JSON::Validator.validate!(createTodoValidator, todo_data)
#   rescue JSON::Schema::ValidationError => e
#     status 400
#     return JSON.generate({
#       errors: e.message
#     })
#   end

#   todo = Todo.new(data['todo'])

#   if todo.save
#     status 201
#     return todo.to_json
#   else
#     status 500
#     return
#   end
# end

put '/todos/:id' do
  content_type :json

  id = params['id']
  todo = Todo.find(id)

  if todo == nil
    status 404
    return
  end

  data = JSON.parse(request.body.read)
  todo_data = data['todo']

  begin
    JSON::Validator.validate!(updateTodoValidator, todo_data)
  rescue JSON::Schema::ValidationError => e
    status 400
    return JSON.generate({
      errors: e.message
    })
  end

  if todo.update(todo_data)
    status 200
    return todo.to_json
  else
    status 500
    return
  end
end
