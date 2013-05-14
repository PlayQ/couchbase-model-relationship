require 'spec_helper'

class Child < Couchbase::Model
  attribute :age
end

class Brother < Couchbase::Model
end

class Sister < Couchbase::Model
end

class ParentTest < Couchbase::Model
  attribute :name

  child :child
end

class MultipleChildTest < Couchbase::Model
  children :brother, :sister
end

describe "parent" do
  subject { ParentTest.new }

  it "has a setter" do
    subject.should respond_to(:child=)
  end

  it "has a getter" do
    subject.should respond_to(:child)
  end

  it "sets and gets the value properly" do
    subject.child = :abc
    subject.child.should eq(:abc)
  end

  it "handles multiple children" do
    MultipleChildTest.new.should respond_to(:brother, :brother=, :sister, :sister=)
  end

  describe ".find_with_children" do
    subject { ParentTest }
    let(:bucket) { stub }

    before do
      subject.stubs(bucket: bucket)
    end

    it "finds and returns the proper objects" do
      bucket.expects(:get).with(
        ["parent:1", "child:1"],
        quiet: true,
        extended: true
      ).returns({
        "parent:1" => [{name: "abc"}, 0, :cas],
        "child:1" => [{age: 5}, 0, :cas]
      })

      parent = subject.find_with_children("parent:1")
      parent.name.should eq("abc")
      parent.child.age.should eq(5)
    end

    it "only finds valid children" do
      bucket.expects(:get).with(
        ["parent:1"],
        quiet: true,
        extended: true
      ).returns({
        "parent:1" => [{name: "abc"}, 0, :cas],
      })

      subject.find_with_children "parent:1", :invalid
    end

    it "raises an error when the parent object isn't found" do
      bucket.expects(:get).with(
        ["parent:1", "child:1"],
        quiet: true,
        extended: true
      ).returns({
        "child:1" => [{age: 5}, 0, :cas]
      })

      expect { subject.find_with_children("parent:1") }.to raise_error(Couchbase::Error::NotFound)
    end

    it "doesn't raise an error when the child object isn't found" do
      bucket.expects(:get).with(
        ["parent:1", "child:1"],
        quiet: true,
        extended: true
      ).returns({
        "parent:1" => [{name: "abc"}, 0, :cas],
      })

      parent = subject.find_with_children("parent:1")
      parent.name.should eq("abc")
      parent.child.should be_nil
    end
  end
end
