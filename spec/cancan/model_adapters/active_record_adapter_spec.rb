if ENV["MODEL_ADAPTER"].nil? || ENV["MODEL_ADAPTER"] == "active_record"
  require "spec_helper"

  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

  describe CanCan::ModelAdapters::ActiveRecordAdapter do
    with_model :category do
      table do |t|
        t.boolean "visible"
      end
      model do
        has_many :articles
      end
    end

    with_model :article do
      table do |t|
        t.string  "name"
        t.boolean "published"
        t.boolean "secret"
        t.integer "priority"
        t.integer "category_id"
        t.integer "user_id"
      end
      model do
        belongs_to :category
        has_many :comments
        belongs_to :user
      end
    end

    with_model :comment do
      table do |t|
        t.boolean "spam"
        t.integer "article_id"
      end
      model do
        belongs_to :article
      end
    end

    with_model :user do
      table do |t|

      end
      model do
        has_many :articles
      end
    end

    before(:each) do
      Article.delete_all
      Comment.delete_all
      (@ability = double).extend(CanCan::Ability)
      @article_table = Article.table_name
      @comment_table = Comment.table_name
    end

    it "is for only active record classes" do
      expect(CanCan::ModelAdapters::ActiveRecordAdapter).to_not be_for_class(Object)
      expect(CanCan::ModelAdapters::ActiveRecordAdapter).to be_for_class(Article)
      expect(CanCan::ModelAdapters::AbstractAdapter.adapter_class(Article)).to eq(CanCan::ModelAdapters::ActiveRecordAdapter)
    end

    it "finds record" do
      article = Article.create!
      expect(CanCan::ModelAdapters::ActiveRecordAdapter.find(Article, article.id)).to eq(article)
    end

    it "does not fetch any records when no abilities are defined" do
      Article.create!
      expect(Article.accessible_by(@ability)).to be_empty
    end

    it "fetches all articles when one can read all" do
      @ability.can :read, Article
      article = Article.create!
      expect(Article.accessible_by(@ability)).to eq([article])
    end

    it "fetches only the articles that are published" do
      @ability.can :read, Article, :published => true
      article1 = Article.create!(:published => true)
      article2 = Article.create!(:published => false)
      expect(Article.accessible_by(@ability)).to eq([article1])
    end

    it "fetches any articles which are published or secret" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, :secret => true
      article1 = Article.create!(:published => true, :secret => false)
      article2 = Article.create!(:published => true, :secret => true)
      article3 = Article.create!(:published => false, :secret => true)
      article4 = Article.create!(:published => false, :secret => false)
      expect(Article.accessible_by(@ability)).to eq([article1, article2, article3])
    end

    it "fetches only the articles that are published and not secret" do
      @ability.can :read, Article, :published => true
      @ability.cannot :read, Article, :secret => true
      article1 = Article.create!(:published => true, :secret => false)
      article2 = Article.create!(:published => true, :secret => true)
      article3 = Article.create!(:published => false, :secret => true)
      article4 = Article.create!(:published => false, :secret => false)
      expect(Article.accessible_by(@ability)).to eq([article1])
    end

    it "only reads comments for articles which are published" do
      @ability.can :read, Comment, :article => { :published => true }
      comment1 = Comment.create!(:article => Article.create!(:published => true))
      comment2 = Comment.create!(:article => Article.create!(:published => false))
      expect(Comment.accessible_by(@ability)).to eq([comment1])
    end

    it "only reads comments for visible categories through articles" do
      @ability.can :read, Comment, :article => { :category => { :visible => true } }
      comment1 = Comment.create!(:article => Article.create!(:category => Category.create!(:visible => true)))
      comment2 = Comment.create!(:article => Article.create!(:category => Category.create!(:visible => false)))
      expect(Comment.accessible_by(@ability)).to eq([comment1])
    end

    it "allows conditions in SQL and merge with hash conditions" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, ["secret=?", true]
      article1 = Article.create!(:published => true, :secret => false)
      article2 = Article.create!(:published => true, :secret => true)
      article3 = Article.create!(:published => false, :secret => true)
      article4 = Article.create!(:published => false, :secret => false)
      expect(Article.accessible_by(@ability)).to eq([article1, article2, article3])
    end

    it "allows a scope for conditions" do
      @ability.can :read, Article, Article.where(:secret => true)
      article1 = Article.create!(:secret => true)
      article2 = Article.create!(:secret => false)
      expect(Article.accessible_by(@ability)).to eq([article1])
    end

    it "fetches only associated records when using with a scope for conditions" do
      @ability.can :read, Article, Article.where(:secret => true)
      category1 = Category.create!(:visible => false)
      category2 = Category.create!(:visible => true)
      article1 = Article.create!(:secret => true, :category => category1)
      article2 = Article.create!(:secret => true, :category => category2)
      expect(category1.articles.accessible_by(@ability)).to eq([article1])
    end

    it "raises an exception when trying to merge scope with other conditions" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, Article.where(:secret => true)
      expect(lambda { Article.accessible_by(@ability) }).to raise_error(CanCan::Error, "Unable to merge an Active Record scope with other conditions. Instead use a hash or SQL for read Article ability.")
    end

    it "does not allow to fetch records when ability with just block present" do
      @ability.can :read, Article do
        false
      end
      expect(lambda { Article.accessible_by(@ability) }).to raise_error(CanCan::Error)
    end

    it "does not allow to check ability on object against SQL conditions without block" do
      @ability.can :read, Article, ["secret=?", true]
      expect(lambda { @ability.can? :read, Article.new }).to raise_error(CanCan::Error)
    end

    it "has false conditions if no abilities match" do
      expect(@ability.model_adapter(Article, :read).conditions).to eq("'t'='f'")
    end

    it "returns false conditions for cannot clause" do
      @ability.cannot :read, Article
      expect(@ability.model_adapter(Article, :read).conditions).to eq("'t'='f'")
    end

    it "returns SQL for single `can` definition in front of default `cannot` condition" do
      @ability.cannot :read, Article
      @ability.can :read, Article, :published => false, :secret => true
      expect(@ability.model_adapter(Article, :read).conditions).to orderlessly_match(%Q["#{@article_table}"."published" = 'f' AND "#{@article_table}"."secret" = 't'])
    end

    it "returns true condition for single `can` definition in front of default `can` condition" do
      @ability.can :read, Article
      @ability.can :read, Article, :published => false, :secret => true
      expect(@ability.model_adapter(Article, :read).conditions).to eq("'t'='t'")
    end

    it "returns `false condition` for single `cannot` definition in front of default `cannot` condition" do
      @ability.cannot :read, Article
      @ability.cannot :read, Article, :published => false, :secret => true
      expect(@ability.model_adapter(Article, :read).conditions).to eq("'t'='f'")
    end

    it "returns `not (sql)` for single `cannot` definition in front of default `can` condition" do
      @ability.can :read, Article
      @ability.cannot :read, Article, :published => false, :secret => true
      expect(@ability.model_adapter(Article, :read).conditions).to orderlessly_match(%Q["not (#{@article_table}"."published" = 'f' AND "#{@article_table}"."secret" = 't')])
    end

    it "returns appropriate sql conditions in complex case" do
      @ability.can :read, Article
      @ability.can :manage, Article, :id => 1
      @ability.can :update, Article, :published => true
      @ability.cannot :update, Article, :secret => true
      expect(@ability.model_adapter(Article, :update).conditions).to eq(%Q[not ("#{@article_table}"."secret" = 't') AND (("#{@article_table}"."published" = 't') OR ("#{@article_table}"."id" = 1))])
      expect(@ability.model_adapter(Article, :manage).conditions).to eq({:id => 1})
      expect(@ability.model_adapter(Article, :read).conditions).to eq("'t'='t'")
    end

    it "returns appropriate sql conditions in complex case with nested joins" do
      @ability.can :read, Comment, :article => { :category => { :visible => true } }
      expect(@ability.model_adapter(Comment, :read).conditions).to eq({ Category.table_name.to_sym => { :visible => true } })
    end

    it "returns appropriate sql conditions in complex case with nested joins of different depth" do
      @ability.can :read, Comment, :article => { :published => true, :category => { :visible => true } }
      expect(@ability.model_adapter(Comment, :read).conditions).to eq({ Article.table_name.to_sym => { :published => true }, Category.table_name.to_sym => { :visible => true } })
    end

    it "does not forget conditions when calling with SQL string" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, ['secret=?', false]
      adapter = @ability.model_adapter(Article, :read)
      2.times do
        expect(adapter.conditions).to eq(%Q[(secret='f') OR ("#{@article_table}"."published" = 't')])
      end
    end

    it "has nil joins if no rules" do
      expect(@ability.model_adapter(Article, :read).joins).to be_nil
    end

    it "has nil joins if no nested hashes specified in conditions" do
      @ability.can :read, Article, :published => false
      @ability.can :read, Article, :secret => true
      expect(@ability.model_adapter(Article, :read).joins).to be_nil
    end

    it "merges separate joins into a single array" do
      @ability.can :read, Article, :project => { :blocked => false }
      @ability.can :read, Article, :company => { :admin => true }
      expect(@ability.model_adapter(Article, :read).joins.inspect).to orderlessly_match([:company, :project].inspect)
    end

    it "merges same joins into a single array" do
      @ability.can :read, Article, :project => { :blocked => false }
      @ability.can :read, Article, :project => { :admin => true }
      expect(@ability.model_adapter(Article, :read).joins).to eq([:project])
    end

    it "merges nested and non-nested joins" do
      @ability.can :read, Article, :project => { :blocked => false }
      @ability.can :read, Article, :project => { :comments => { :spam => true } }
      expect(@ability.model_adapter(Article, :read).joins).to eq([{:project=>[:comments]}])
    end

    it "merges :all conditions with other conditions" do
      user = User.create!
      article = Article.create!(:user => user)
      ability = Ability.new(user)
      ability.can :manage, :all
      ability.can :manage, Article, :user_id => user.id
      expect(Article.accessible_by(ability)).to eq([article])
    end

    it "restricts articles given a MetaWhere condition" do
      @ability.can :read, Article, :priority.lt => 2
      article1 = Article.create!(:priority => 1)
      article2 = Article.create!(:priority => 3)
      expect(Article.accessible_by(@ability)).to eq([article1])
      expect(@ability).to be_able_to(:read, article1)
      expect(@ability).to_not be_able_to(:read, article2)
    end

    it "merges MetaWhere and non-MetaWhere conditions" do
      @ability.can :read, Article, :priority.lt => 2
      @ability.can :read, Article, :priority => 1
      article1 = Article.create!(:priority => 1)
      article2 = Article.create!(:priority => 3)
      expect(Article.accessible_by(@ability)).to eq([article1])
      expect(@ability).to be_able_to(:read, article1)
      expect(@ability).to_not be_able_to(:read, article2)
    end

    it "matches any MetaWhere condition" do
      adapter = CanCan::ModelAdapters::ActiveRecordAdapter
      article1 = Article.new(:priority => 1, :name => "Hello World")
      expect(adapter.matches_condition?(article1, :priority.eq, 1)).to be_true
      expect(adapter.matches_condition?(article1, :priority.eq, 2)).to be_false
      expect(adapter.matches_condition?(article1, :priority.eq_any, [1, 2])).to be_true
      expect(adapter.matches_condition?(article1, :priority.eq_any, [2, 3])).to be_false
      expect(adapter.matches_condition?(article1, :priority.eq_all, [1, 1])).to be_true
      expect(adapter.matches_condition?(article1, :priority.eq_all, [1, 2])).to be_false
      expect(adapter.matches_condition?(article1, :priority.ne, 2)).to be_true
      expect(adapter.matches_condition?(article1, :priority.ne, 1)).to be_false
      expect(adapter.matches_condition?(article1, :priority.in, [1, 2])).to be_true
      expect(adapter.matches_condition?(article1, :priority.in, [2, 3])).to be_false
      expect(adapter.matches_condition?(article1, :priority.nin, [2, 3])).to be_true
      expect(adapter.matches_condition?(article1, :priority.nin, [1, 2])).to be_false
      expect(adapter.matches_condition?(article1, :priority.lt, 2)).to be_true
      expect(adapter.matches_condition?(article1, :priority.lt, 1)).to be_false
      expect(adapter.matches_condition?(article1, :priority.lteq, 1)).to be_true
      expect(adapter.matches_condition?(article1, :priority.lteq, 0)).to be_false
      expect(adapter.matches_condition?(article1, :priority.gt, 0)).to be_true
      expect(adapter.matches_condition?(article1, :priority.gt, 1)).to be_false
      expect(adapter.matches_condition?(article1, :priority.gteq, 1)).to be_true
      expect(adapter.matches_condition?(article1, :priority.gteq, 2)).to be_false
      expect(adapter.matches_condition?(article1, :name.like, "%ello worl%")).to be_true
      expect(adapter.matches_condition?(article1, :name.like, "hello world")).to be_true
      expect(adapter.matches_condition?(article1, :name.like, "hello%")).to be_true
      expect(adapter.matches_condition?(article1, :name.like, "h%d")).to be_true
      expect(adapter.matches_condition?(article1, :name.like, "%helo%")).to be_false
      expect(adapter.matches_condition?(article1, :name.like, "hello")).to be_false
      expect(adapter.matches_condition?(article1, :name.like, "hello.world")).to be_false
      # For some reason this is reporting "The not_matches MetaWhere condition is not supported."
      # expect(adapter.matches_condition?(article1, :name.nlike, "%helo%")).to be_true
      # expect(adapter.matches_condition?(article1, :name.nlike, "%ello worl%")).to be_false
    end
  end
end
