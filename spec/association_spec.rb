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

  it "knows if the parent is loaded" do
    parent = stub(abc_loaded?: :blarg)

    subject.new("abc").loaded?(parent).should eq(:blarg)
  end

  it "loads the object from the database" do
    child_class = stub_klass(Couchbase::Model)
    child_class.expects(:prefixed_id).with('core/user:abc123').returns(:id)
    child_class.expects(:find_by_id).with(:id).returns(:child)

    parent = stub(id: "core/user:abc123")
    instance = subject.new("string")
    instance.stubs(child_class: child_class)

    instance.load(parent).should eq(:child)
  end

  it "knows the child class name" do
    subject.new("string").child_klass.should eq("String")
  end
  
  it "knows the child class" do
    subject.new("string").child_class.should eq(String)
  end
end
