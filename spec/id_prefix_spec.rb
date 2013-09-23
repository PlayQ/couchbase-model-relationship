require 'spec_helper'

class IdPrefixTest < Couchbase::Model
end

describe "IdPrefix" do
  subject { IdPrefixTest.new }

  it "unprefixes it's own id" do
    subject.send(:ensure_has_id)

    subject.unprefixed_id.should eq(subject.id.split(':').last)
  end

  it "knows the proper prefix" do
    subject.class.id_prefix.should eq("id_prefix_test")
  end

  it "prefixes an id properly" do
    subject.class.prefixed_id(123).should eq("id_prefix_test:123")
  end

  it "unprefixes an id properly" do
    subject.class.unprefixed_id("klass:123").should eq("123")
  end

  it "gets the prefix for an id properly" do
    subject.class.prefix_from_id("class:abc").should eq("class")
  end

  it "gets the class for an id prperly" do
    subject.class.class_from_id("id_prefix_test").should eq(IdPrefixTest)
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
