require 'rack'
require 'sqlite3'
require 'pp'

class Application
  def initialize
    @template = File.read('./todo-list/views/index.erb')#
    @db = SQLite3::Database.new('./todo-list/db/database.sqlite3')
    @db.results_as_hash = true
    @display_modal = false
  end

  def call(env)
    res = Rack::Response.new
    req = Rack::Request.new(env)

    if req.POST.any?
      data = req.POST

      if data['newListName']
        new_list = data['newListName']

        @db.execute("INSERT INTO lists (name) VALUES ('#{new_list}');")
      elsif data['taskName']
        new_task = data['taskName']
        list_id = data['list']

        @db.execute("INSERT INTO todos (task, list_id) VALUES ('#{new_task}', '#{list_id}');")
      elsif data['newTaskName']
        task = data['newTaskName']
        task_id = data['taskID']

        @db.execute("UPDATE todos SET task='#{task}' WHERE id='#{task_id}'")
        @display_modal = false
      elsif data['delete_list']
        list_id = data['delete_list']

        @db.execute("DELETE FROM lists WHERE id='#{list_id}'")
        @db.execute("DELETE FROM todos WHERE list_id='#{list_id}'")
      end


    end

    if req.params['edit']
      @task_id = req.params['edit']
      @display_modal = true

    elsif req.params['done']
      task_id = req.params['done']

      @db.execute("UPDATE todos SET done=true WHERE id='#{task_id}'")

    elsif req.params['restore']
      task_id = req.params['restore']

      @db.execute("UPDATE todos SET done=false WHERE id='#{task_id}'")

    elsif req.params['delete']
      task_id = req.params['delete']

      @db.execute("DELETE FROM todos WHERE id='#{task_id}'")

    end

    @lists = @db.execute("SELECT * FROM lists;")


    res.write ERB.new(@template).result(binding)
    res.finish
  end
end