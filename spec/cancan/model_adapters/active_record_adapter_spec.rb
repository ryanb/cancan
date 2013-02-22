if ENV["MODEL_ADAPTER"].nil? || ENV["MODEL_ADAPTER"] == "active_record"
  require "spec_helper"

  class Category
    has_many :articles
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

  describe CanCan::ModelAdapters::ActiveRecordAdapter do
    before(:each) do
      Article.delete_all
      Comment.delete_all
      @ability = Object.new
      @ability.extend(CanCan::Ability)
      @article_table = Article.table_name
      @comment_table = Comment.table_name
    end

    it "is for only active record classes" do
      CanCan::ModelAdapters::ActiveRecordAdapter.should_not be_for_class(Object)
      CanCan::ModelAdapters::ActiveRecordAdapter.should be_for_class(Article)
      CanCan::ModelAdapters::AbstractAdapter.adapter_class(Article).should == CanCan::ModelAdapters::ActiveRecordAdapter
    end

    it "finds record" do
      article = Article.create!
      CanCan::ModelAdapters::ActiveRecordAdapter.find(Article, article.id).should == article
    end

    it "does not fetch any records when no abilities are defined" do
      Article.create!
      Article.accessible_by(@ability).should be_empty
    end

    it "fetches all articles when one can read all" do
      @ability.can :read, :articles
      article = Article.create!
      Article.accessible_by(@ability).should == [article]
    end

    it "fetches only the articles that are published" do
      @ability.can :read, :articles, :published => true
      article1 = Article.create!(:published => true)
      article2 = Article.create!(:published => false)
      Article.accessible_by(@ability).should == [article1]
    end

    it "fetches any articles which are published or secret" do
      @ability.can :read, :articles, :published => true
      @ability.can :read, :articles, :secret => true
      article1 = Article.create!(:published => true, :secret => false)
      article2 = Article.create!(:published => true, :secret => true)
      article3 = Article.create!(:published => false, :secret => true)
      article4 = Article.create!(:published => false, :secret => false)
      Article.accessible_by(@ability).should == [article1, article2, article3]
    end

    it "fetches only the articles that are published and not secret" do
      @ability.can :read, :articles, :published => true
      @ability.cannot :read, :articles, :secret => true
      article1 = Article.create!(:published => true, :secret => false)
      article2 = Article.create!(:published => true, :secret => true)
      article3 = Article.create!(:published => false, :secret => true)
      article4 = Article.create!(:published => false, :secret => false)
      Article.accessible_by(@ability).should == [article1]
    end

    it "only reads comments for articles which are published" do
      @ability.can :read, :comments, :article => { :published => true }
      comment1 = Comment.create!(:article => Article.create!(:published => true))
      comment2 = Comment.create!(:article => Article.create!(:published => false))
      Comment.accessible_by(@ability).should == [comment1]
    end

    it "only reads comments for visible categories through articles" do
      @ability.can :read, :comments, :article => { :category => { :visible => true } }
      comment1 = Comment.create!(:article => Article.create!(:category => Category.create!(:visible => true)))
      comment2 = Comment.create!(:article => Article.create!(:category => Category.create!(:visible => false)))
      Comment.accessible_by(@ability).should == [comment1]
    end

    it "allows conditions in SQL and merge with hash conditions" do
      @ability.can :read, :articles, :published => true
      @ability.can :read, :articles, ["secret=?", true]
      article1 = Article.create!(:published => true, :secret => false)
      article2 = Article.create!(:published => true, :secret => true)
      article3 = Article.create!(:published => false, :secret => true)
      article4 = Article.create!(:published => false, :secret => false)
      Article.accessible_by(@ability).should == [article1, article2, article3]
    end

    it "allows a scope for conditions" do
      @ability.can :read, :articles, Article.where(:secret => true)
      article1 = Article.create!(:secret => true)
      article2 = Article.create!(:secret => false)
      Article.accessible_by(@ability).should == [article1]
    end

    it "fetches only associated records when using with a scope for conditions" do
      @ability.can :read, :articles, Article.where(:secret => true)
      category1 = Category.create!(:visible => false)
      category2 = Category.create!(:visible => true)
      article1 = Article.create!(:secret => true, :category => category1)
      article2 = Article.create!(:secret => true, :category => category2)
      # for some reason the objects aren't comparing equally here so it's necessary to compare by id
      category1.articles.accessible_by(@ability).map(&:id).should == [article1.id]
    end

    it "raises an exception when trying to merge scope with other conditions" do
      @ability.can :read, :articles, :published => true
      @ability.can :read, :articles, Article.where(:secret => true)
      lambda { Article.accessible_by(@ability) }.should raise_error(CanCan::Error, "Unable to merge an Active Record scope with other conditions. Instead use a hash or SQL for read articles ability.")
    end

    it "does not allow to fetch records when ability with just block present" do
      @ability.can :read, :articles do
        false
      end
      lambda { Article.accessible_by(@ability) }.should raise_error(CanCan::Error)
    end

    it "does not allow to check ability on object against SQL conditions without block" do
      @ability.can :read, :articles, ["secret=?", true]
      lambda { @ability.can? :read, Article.new }.should raise_error(CanCan::Error)
    end

    it "has false conditions if no abilities match" do
      @ability.model_adapter(Article, :read).conditions.should == "'t'='f'"
    end

    it "returns false conditions for cannot clause" do
      @ability.cannot :read, :articles
      @ability.model_adapter(Article, :read).conditions.should == "'t'='f'"
    end

    it "returns SQL for single `can` definition in front of default `cannot` condition" do
      @ability.cannot :read, :articles
      @ability.can :read, :articles, :published => false, :secret => true
      @ability.model_adapter(Article, :read).conditions.should orderlessly_match(%Q["#{@article_table}"."published" = 'f' AND "#{@article_table}"."secret" = 't'])
    end

    it "returns true condition for single `can` definition in front of default `can` condition" do
      @ability.can :read, :articles
      @ability.can :read, :articles, :published => false, :secret => true
      @ability.model_adapter(Article, :read).conditions.should eq(:secret => true, :published => false)
    end

    it "returns `false condition` for single `cannot` definition in front of default `cannot` condition" do
      @ability.cannot :read, :articles
      @ability.cannot :read, :articles, :published => false, :secret => true
      @ability.model_adapter(Article, :read).conditions.should  == "'t'='f'"
    end

    it "returns `not (sql)` for single `cannot` definition in front of default `can` condition" do
      @ability.can :read, :articles
      @ability.cannot :read, :articles, :published => false, :secret => true
      @ability.model_adapter(Article, :read).conditions.should orderlessly_match(%Q["not (#{@article_table}"."published" = 'f' AND "#{@article_table}"."secret" = 't')])
    end

    it "returns appropriate sql conditions in complex case" do
      @ability.can :read, :articles
      @ability.can :access, :articles, :id => 1
      @ability.can :update, :articles, :published => true
      @ability.cannot :update, :articles, :secret => true
      @ability.model_adapter(Article, :update).conditions.should == %Q[not ("#{@article_table}"."secret" = 't') AND (("#{@article_table}"."published" = 't') OR ("#{@article_table}"."id" = 1))]
      @ability.model_adapter(Article, :access).conditions.should == {:id => 1}
      @ability.model_adapter(Article, :read).conditions.should == {:id => 1} # used to be "t=t" but changed with new specificity rule (issue #321)
    end

    it "does not forget conditions when calling with SQL string" do
      @ability.can :read, :articles, :published => true
      @ability.can :read, :articles, ['secret=?', false]
      adapter = @ability.model_adapter(Article, :read)
      2.times do
        adapter.conditions.should == %Q[(secret='f') OR ("#{@article_table}"."published" = 't')]
      end
    end

    it "has nil joins if no rules" do
      @ability.model_adapter(Article, :read).joins.should be_nil
    end

    it "has nil joins if no nested hashes specified in conditions" do
      @ability.can :read, :articles, :published => false
      @ability.can :read, :articles, :secret => true
      @ability.model_adapter(Article, :read).joins.should be_nil
    end

    it "merges separate joins into a single array" do
      @ability.can :read, :articles, :project => { :blocked => false }
      @ability.can :read, :articles, :company => { :admin => true }
      @ability.model_adapter(Article, :read).joins.inspect.should orderlessly_match([:company, :project].inspect)
    end

    it "merges same joins into a single array" do
      @ability.can :read, :articles, :project => { :blocked => false }
      @ability.can :read, :articles, :project => { :admin => true }
      @ability.model_adapter(Article, :read).joins.should == [:project]
    end

    it "restricts articles given a MetaWhere condition" do
      @ability.can :read, :articles, :priority.lt => 2
      article1 = Article.create!(:priority => 1)
      article2 = Article.create!(:priority => 3)
      Article.accessible_by(@ability).should == [article1]
      @ability.can?(:read, article1).should be_true
      @ability.should_not be_able_to(:read, article2)
    end

    it "should merge MetaWhere and non-MetaWhere conditions" do
      @ability.can :read, :articles, :priority.lt => 2
      @ability.can :read, :articles, :priority => 1
      article1 = Article.create!(:priority => 1)
      article2 = Article.create!(:priority => 3)
      Article.accessible_by(@ability).should == [article1]
      @ability.should be_able_to(:read, article1)
      @ability.should_not be_able_to(:read, article2)
    end

    it "matches any MetaWhere condition" do
      adapter = CanCan::ModelAdapters::ActiveRecordAdapter
      article1 = Article.new(:priority => 1, :name => "Hello World")
      adapter.matches_condition?(article1, :priority.eq, 1).should be_true
      adapter.matches_condition?(article1, :priority.eq, 2).should be_false
      adapter.matches_condition?(article1, :priority.eq_any, [1, 2]).should be_true
      adapter.matches_condition?(article1, :priority.eq_any, [2, 3]).should be_false
      adapter.matches_condition?(article1, :priority.eq_all, [1, 1]).should be_true
      adapter.matches_condition?(article1, :priority.eq_all, [1, 2]).should be_false
      adapter.matches_condition?(article1, :priority.ne, 2).should be_true
      adapter.matches_condition?(article1, :priority.ne, 1).should be_false
      adapter.matches_condition?(article1, :priority.in, [1, 2]).should be_true
      adapter.matches_condition?(article1, :priority.in, [2, 3]).should be_false
      adapter.matches_condition?(article1, :priority.nin, [2, 3]).should be_true
      adapter.matches_condition?(article1, :priority.nin, [1, 2]).should be_false
      adapter.matches_condition?(article1, :priority.lt, 2).should be_true
      adapter.matches_condition?(article1, :priority.lt, 1).should be_false
      adapter.matches_condition?(article1, :priority.lteq, 1).should be_true
      adapter.matches_condition?(article1, :priority.lteq, 0).should be_false
      adapter.matches_condition?(article1, :priority.gt, 0).should be_true
      adapter.matches_condition?(article1, :priority.gt, 1).should be_false
      adapter.matches_condition?(article1, :priority.gteq, 1).should be_true
      adapter.matches_condition?(article1, :priority.gteq, 2).should be_false
      adapter.matches_condition?(article1, :name.like, "%ello worl%").should be_true
      adapter.matches_condition?(article1, :name.like, "hello world").should be_true
      adapter.matches_condition?(article1, :name.like, "hello%").should be_true
      adapter.matches_condition?(article1, :name.like, "h%d").should be_true
      adapter.matches_condition?(article1, :name.like, "%helo%").should be_false
      adapter.matches_condition?(article1, :name.like, "hello").should be_false
      adapter.matches_condition?(article1, :name.like, "hello.world").should be_false
      adapter.matches_condition?(article1, :name.nlike, "%helo%").should be_true
      adapter.matches_condition?(article1, :name.nlike, "%ello worl%").should be_false
    end
  end
end
