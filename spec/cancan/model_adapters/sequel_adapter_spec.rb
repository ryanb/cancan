if ENV["MODEL_ADAPTER"] == "sequel"
  require "spec_helper"

  DB = Sequel.sqlite

  DB.create_table :users do
    primary_key :id
    String :name
  end

  class User < Sequel::Model
    one_to_many :articles
  end

  DB.create_table :articles do
    primary_key :id
    String :name
    TrueClass :published
    TrueClass :secret
    Integer :priority
    foreign_key :user_id, :users
  end

  class Article < Sequel::Model
    many_to_one :user
    one_to_many :comments
  end

  DB.create_table :comments do
    primary_key :id
    TrueClass :spam
    foreign_key :article_id, :articles
  end

  class Comment < Sequel::Model
    many_to_one :article
  end

  describe CanCan::ModelAdapters::SequelAdapter do
    before(:each) do
      Comment.dataset.delete
      Article.dataset.delete
      User.dataset.delete
      @ability = Object.new
      @ability.extend(CanCan::Ability)
    end

    it "should be for only sequel model classes" do
      CanCan::ModelAdapters::SequelAdapter.should_not be_for_class(Object)
      CanCan::ModelAdapters::SequelAdapter.should be_for_class(Article)
      CanCan::ModelAdapters::AbstractAdapter.adapter_class(Article).should == CanCan::ModelAdapters::SequelAdapter
    end

    it "should find record" do
      article = Article.create
      CanCan::ModelAdapters::SequelAdapter.find(Article, article.id).should == article
    end

    it "should not fetch any records when no abilities are defined" do
      Article.create
      Article.accessible_by(@ability).all.should be_empty
    end

    it "should fetch all articles when one can read all" do
      @ability.can :read, Article
      article = Article.create
      @ability.should be_able_to(:read, article)
      Article.accessible_by(@ability).all.should == [article]
    end

    it "should fetch only the articles that are published" do
      @ability.can :read, Article, :published => true
      article1 = Article.create(:published => true)
      article2 = Article.create(:published => false)
      @ability.should be_able_to(:read, article1)
      @ability.should_not be_able_to(:read, article2)
      Article.accessible_by(@ability).all.should == [article1]
    end

    it "should fetch any articles which are published or secret" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, :secret => true
      article1 = Article.create(:published => true, :secret => false)
      article2 = Article.create(:published => true, :secret => true)
      article3 = Article.create(:published => false, :secret => true)
      article4 = Article.create(:published => false, :secret => false)
      @ability.should be_able_to(:read, article1)
      @ability.should be_able_to(:read, article2)
      @ability.should be_able_to(:read, article3)
      @ability.should_not be_able_to(:read, article4)
      Article.accessible_by(@ability).all.should == [article1, article2, article3]
    end

    it "should fetch only the articles that are published and not secret" do
      @ability.can :read, Article, :published => true
      @ability.cannot :read, Article, :secret => true
      article1 = Article.create(:published => true, :secret => false)
      article2 = Article.create(:published => true, :secret => true)
      article3 = Article.create(:published => false, :secret => true)
      article4 = Article.create(:published => false, :secret => false)
      @ability.should be_able_to(:read, article1)
      @ability.should_not be_able_to(:read, article2)
      @ability.should_not be_able_to(:read, article3)
      @ability.should_not be_able_to(:read, article4)
      Article.accessible_by(@ability).all.should == [article1]
    end

    it "should only read comments for articles which are published" do
      @ability.can :read, Comment, :article => { :published => true }
      comment1 = Comment.create(:article => Article.create(:published => true))
      comment2 = Comment.create(:article => Article.create(:published => false))
      @ability.should be_able_to(:read, comment1)
      @ability.should_not be_able_to(:read, comment2)
      Comment.accessible_by(@ability).all.should == [comment1]
    end

    it "should only read comments for articles which are published and user is 'me'" do
      @ability.can :read, Comment, :article => { :user => { :name => 'me' }, :published => true }
      user1 = User.create(:name => 'me')
      comment1 = Comment.create(:article => Article.create(:published => true, :user => user1))
      comment2 = Comment.create(:article => Article.create(:published => true))
      comment3 = Comment.create(:article => Article.create(:published => false, :user => user1))
      @ability.should be_able_to(:read, comment1)
      @ability.should_not be_able_to(:read, comment2)
      @ability.should_not be_able_to(:read, comment3)
      Comment.accessible_by(@ability).all.should == [comment1]
    end

    it "should allow conditions in SQL and merge with hash conditions" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, ["secret=?", true] do |article|
        article.secret
      end
      @ability.cannot :read, Article, "priority > 1" do |article|
        article.priority > 1
      end
      article1 = Article.create(:published => true, :secret => false, :priority => 1)
      article2 = Article.create(:published => true, :secret => true, :priority => 1)
      article3 = Article.create(:published => true, :secret => true, :priority => 2)
      article4 = Article.create(:published => false, :secret => false, :priority => 2)
      @ability.should be_able_to(:read, article1)
      @ability.should be_able_to(:read, article2)
      @ability.should_not be_able_to(:read, article3)
      @ability.should_not be_able_to(:read, article4)
      Article.accessible_by(@ability).all.should == [article1, article2]
    end
  end
end
