if ENV["MODEL_ADAPTER"] == "data_mapper"
  require "spec_helper"

  DataMapper.setup(:default, 'sqlite::memory:')

  class Article
    include DataMapper::Resource
    property :id, Serial
    property :published, Boolean, :default => false
    property :secret, Boolean, :default => false
    property :priority, Integer
    has n, :comments
  end

  class Comment
    include DataMapper::Resource
    property :id, Serial
    property :spam, Boolean, :default => false
    belongs_to :article
  end

  DataMapper.finalize
  DataMapper.auto_migrate!

  describe CanCan::ModelAdapters::DataMapperAdapter do
    before(:each) do
      Article.destroy
      Comment.destroy
      @ability = Object.new
      @ability.extend(CanCan::Ability)
    end

    it "should be for only data mapper classes" do
      CanCan::ModelAdapters::DataMapperAdapter.should_not be_for_class(Object)
      CanCan::ModelAdapters::DataMapperAdapter.should be_for_class(Article)
      CanCan::ModelAdapters::AbstractAdapter.adapter_class(Article).should == CanCan::ModelAdapters::DataMapperAdapter
    end

    it "should find record" do
      article = Article.create
      CanCan::ModelAdapters::DataMapperAdapter.find(Article, article.id).should == article
    end

    it "should not fetch any records when no abilities are defined" do
      Article.create
      Article.accessible_by(@ability).should be_empty
    end

    it "should fetch all articles when one can read all" do
      @ability.can :read, Article
      article = Article.create
      Article.accessible_by(@ability).should == [article]
    end

    it "should fetch only the articles that are published" do
      @ability.can :read, Article, :published => true
      article1 = Article.create(:published => true)
      article2 = Article.create(:published => false)
      Article.accessible_by(@ability).should == [article1]
    end

    it "should fetch any articles which are published or secret" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, :secret => true
      article1 = Article.create(:published => true, :secret => false)
      article2 = Article.create(:published => true, :secret => true)
      article3 = Article.create(:published => false, :secret => true)
      article4 = Article.create(:published => false, :secret => false)
      Article.accessible_by(@ability).should == [article1, article2, article3]
    end

    it "should fetch only the articles that are published and not secret" do
      @ability.can :read, Article, :published => true
      @ability.cannot :read, Article, :secret => true
      article1 = Article.create(:published => true, :secret => false)
      article2 = Article.create(:published => true, :secret => true)
      article3 = Article.create(:published => false, :secret => true)
      article4 = Article.create(:published => false, :secret => false)
      Article.accessible_by(@ability).should == [article1]
    end

    it "should only read comments for articles which are published" do
      @ability.can :read, Comment, :article => { :published => true }
      comment1 = Comment.create(:article => Article.create!(:published => true))
      comment2 = Comment.create(:article => Article.create!(:published => false))
      Comment.accessible_by(@ability).should == [comment1]
    end

    it "should allow conditions in SQL and merge with hash conditions" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, ["secret=?", true]
      article1 = Article.create(:published => true, :secret => false)
      article4 = Article.create(:published => false, :secret => false)
      Article.accessible_by(@ability).should == [article1]
    end

    it "should match gt comparison" do
      @ability.can :read, Article, :priority.gt => 3
      article1 = Article.create(:priority => 4)
      article2 = Article.create(:priority => 3)
      Article.accessible_by(@ability).should == [article1]
      @ability.should be_able_to(:read, article1)
      @ability.should_not be_able_to(:read, article2)
    end

    it "should match gte comparison" do
      @ability.can :read, Article, :priority.gte => 3
      article1 = Article.create(:priority => 4)
      article2 = Article.create(:priority => 3)
      article3 = Article.create(:priority => 2)
      Article.accessible_by(@ability).should == [article1, article2]
      @ability.should be_able_to(:read, article1)
      @ability.should be_able_to(:read, article2)
      @ability.should_not be_able_to(:read, article3)
    end

    # TODO: add more comparison specs
  end
end
