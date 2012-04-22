ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

class Category < ActiveRecord::Base
  connection.create_table(table_name) do |t|
    t.boolean :visible
  end
  has_many :articles
  has_many :projects
end

class Project < ActiveRecord::Base
  connection.create_table(table_name) do |t|
    t.integer :category_id
    t.string :name
  end
  belongs_to :category
end

class Article < ActiveRecord::Base
  connection.create_table(table_name) do |t|
    t.integer :category_id
    t.string :name
    t.boolean :published
    t.boolean :secret
    t.integer :priority
  end
  belongs_to :category
  has_many :comments
end

class Comment < ActiveRecord::Base
  connection.create_table(table_name) do |t|
    t.integer :article_id
    t.boolean :spam
  end
  belongs_to :article
end
