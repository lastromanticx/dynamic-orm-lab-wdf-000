require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'
class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = "pragma table_info(#{table_name})"
    
    table_info = DB[:conn].execute(sql)
    table_info.inject([]){|columns,row| columns << row["name"] unless row["name"].nil?}
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if{|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each{|col| values << "'#{send(col)}'" unless col == "id"}
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} 
      (#{col_names_for_insert})
      VALUES (#{values_for_insert}) 
      SQL

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = ?
      SQL

    DB[:conn].execute(sql,name)
  end

  def self.find_by(hash)
    col_name = hash.keys[0].to_s
    value = hash.values[0]

    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{col_name} = ?
      SQL

    DB[:conn].execute(sql,value)
  end
end
