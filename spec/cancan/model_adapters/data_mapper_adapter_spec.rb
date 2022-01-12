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
      (@ability = double).extend(CanCan::Ability)
    end

    it "is for only data mapper classes" do
      expect(CanCan::ModelAdapters::DataMapperAdapter).not_to be_for_class(Object)
      expect(CanCan::ModelAdapters::DataMapperAdapter).to be_for_class(Article)
      expect(CanCan::ModelAdapters::AbstractAdapter.adapter_class(Article)).to eq(CanCan::ModelAdapters::DataMapperAdapter)
    end

    it "finds record" do
      article = Article.create
      expect(CanCan::ModelAdapters::DataMapperAdapter.find(Article, article.id)).to eq(article)
    end

    it "does not fetch any records when no abilities are defined" do
      Article.create
      expect(Article.accessible_by(@ability)).to be_empty
    end

    it "fetches all articles when one can read all" do
      @ability.can :read, Article
      article = Article.create
      expect(Article.accessible_by(@ability)).to eq([article])
    end

    it "fetches only the articles that are published" do
      @ability.can :read, Article, :published => true
      article1 = Article.create(:published => true)
      article2 = Article.create(:published => false)
      expect(Article.accessible_by(@ability)).to eq([article1])
    end

    it "fetches any articles which are published or secret" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, :secret => true
      article1 = Article.create(:published => true, :secret => false)
      article2 = Article.create(:published => true, :secret => true)
      article3 = Article.create(:published => false, :secret => true)
      article4 = Article.create(:published => false, :secret => false)
      expect(Article.accessible_by(@ability)).to eq([article1, article2, article3])
    end

    it "fetches only the articles that are published and not secret" do
      @ability.can :read, Article, :published => true
      @ability.cannot :read, Article, :secret => true
      article1 = Article.create(:published => true, :secret => false)
      article2 = Article.create(:published => true, :secret => true)
      article3 = Article.create(:published => false, :secret => true)
      article4 = Article.create(:published => false, :secret => false)
      expect(Article.accessible_by(@ability)).to eq([article1])
    end

    it "only reads comments for articles which are published" do
      @ability.can :read, Comment, :article => { :published => true }
      comment1 = Comment.create(:article => Article.create!(:published => true))
      comment2 = Comment.create(:article => Article.create!(:published => false))
      expect(Comment.accessible_by(@ability)).to eq([comment1])
    end

    it "allows conditions in SQL and merge with hash conditions" do
      @ability.can :read, Article, :published => true
      @ability.can :read, Article, ["secret=?", true]
      article1 = Article.create(:published => true, :secret => false)
      article4 = Article.create(:published => false, :secret => false)
      expect(Article.accessible_by(@ability)).to eq([article1])
    end

    it "matches gt comparison" do
      @ability.can :read, Article, :priority.gt => 3
      article1 = Article.create(:priority => 4)
      article2 = Article.create(:priority => 3)
      expect(Article.accessible_by(@ability)).to eq([article1])
      expect(@ability).to be_able_to(:read, article1)
      expect(@ability).not_to be_able_to(:read, article2)
    end

    it "matches gte comparison" do
      @ability.can :read, Article, :priority.gte => 3
      article1 = Article.create(:priority => 4)
      article2 = Article.create(:priority => 3)
      article3 = Article.create(:priority => 2)
      expect(Article.accessible_by(@ability)).to eq([article1, article2])
      expect(@ability).to be_able_to(:read, article1)
      expect(@ability).to be_able_to(:read, article2)
      expect(@ability).not_to be_able_to(:read, article3)
    end

    # TODO: add more comparison specs
  end
end
