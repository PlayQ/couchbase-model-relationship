require 'spec_helper'

describe "associations" do
  subject { ::Couchbase::Model::Relationship::Association }

  it "sets the name" do
    subject.new('abc').name.should eq('abc')
  end

  it "sets autosave properly" do
    subject.new('abc', auto_save: true).auto_save.should be_true
    subject.new('abc').auto_save.should be_false
  end

  it "sets autodelete properly" do
    subject.new('abc', auto_delete: true).auto_delete.should be_true
    subject.new('abc').auto_delete.should be_false
  end

  it "uses the provide class name" do
    subject.new('abc', class_name: "String").child_klass.should eq('String')
  end

  it "fetches the object from the parent" do
    parent = stub(abc: :object)

    subject.new("abc").fetch(parent).should eq(:object)
  end

  it "knows the child class name" do
    subject.new("string").child_klass.should eq("String")
  end
  
  it "knows the child class" do
    subject.new("string").child_class.should eq(String)
  end
end
