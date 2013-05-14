require 'spec_helper'

class IdPrefixTest < Couchbase::Model
end

describe "IdPrefix" do
  subject { IdPrefixTest.new }

  it "knows the proper prefix" do
    subject.class.id_prefix.should eq("id_prefix_test")
  end

  it "prefixes an id properly" do
    subject.class.prefixed_id(123).should eq("id_prefix_test:123")
  end

  it "unprefixes an id properly" do
    subject.class.unprefixed_id("klass:123").should eq("123")
  end

  describe "creating" do 
    before do
      subject.stubs(create_without_id_prefix: true)
    end

    it "doesn't set the id if present" do
      subject.id = 123
      subject.create
      subject.id.should eq(123)
    end

    it "creates a uid with a prefix" do
      subject.create
      subject.id.should match(/^id_prefix_test:/)
    end
  end
end
