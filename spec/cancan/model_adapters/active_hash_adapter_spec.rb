if ENV["MODEL_ADAPTER"] == "active_hash"
  require "spec_helper"

  # override some methods here to help cleanup and id generation
  class ModelBase < ActiveHash::Base
    @@id = 0

    # remove existing records and reset our index
    def self.reset!
      self.data = []
      @@id = 0
    end

    # @override to auto increment the ID
    def create(attributes = {})
      super(attributes.merge(:id => (@@id += 1)))
    end
  end

  class Article < ModelBase
    fields :published, :secret
  end

  describe CanCan::ModelAdapters::ActiveHashAdapter do
    before(:each) do
      Article.reset!
      @ability = Object.new
      @ability.extend(CanCan::Ability)
    end

    it "should be for only active hash classes" do
      CanCan::ModelAdapters::ActiveHashAdapter.should_not be_for_class(Object)
      CanCan::ModelAdapters::ActiveHashAdapter.should be_for_class(Article)
      CanCan::ModelAdapters::AbstractAdapter.adapter_class(Article).should == CanCan::ModelAdapters::ActiveHashAdapter
    end

    it "should find record" do
      article = Article.create
      CanCan::ModelAdapters::ActiveHashAdapter.find(Article, 1).should == article
    end

    it "should not fetch any records when no abilities are defined" do
      article = Article.create
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
      Article.accessible_by(@ability).should =~ [article1, article2, article3]
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
  end
end
