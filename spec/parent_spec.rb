require 'spec_helper'

class Child < Couchbase::Model
  attribute :age

  has_parent
end

class Brother < Couchbase::Model
  has_parent
end

class Sister < Couchbase::Model
  has_parent
end

class ParentTest < Couchbase::Model
  attribute :name

  child :child
end

class AutoSaveTest < Couchbase::Model
  attribute :name

  child :child, auto_save: true
  child :brother, auto_save: false
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
    subject.child = (brother = Brother.new)
    subject.child.should eq(brother)
  end

  it "handles multiple children" do
    MultipleChildTest.new.should respond_to(:brother, :brother=, :sister, :sister=)
  end

  it "saves dirty children if we want to save them" do
    subject = MultipleChildTest.new
    subject.brother = Brother.new
    subject.brother.stubs(changed?: true)
    subject.brother.expects(:save)
    subject.sister = Sister.new
    subject.sister.stubs(changed?: false)
    subject.sister.expects(:save).never

    subject.stubs(save: :saved)

    subject.save_with_children.should eq(:saved)
  end

  it "auto-saves children marked as autosaved" do
    subject = AutoSaveTest.new name: "Test"
    subject.child = Child.new age: 5
    subject.brother = Brother.new

    subject.stubs(save_without_autosave_children: true)

    subject.child.expects(:save_if_changed)
    subject.brother.expects(:save_if_changed).never

    subject.save
  end

  it "deletes children when we're deleted" do
    subject = MultipleChildTest.new
    subject.brother = Brother.new
    subject.brother.expects(:delete)
    subject.sister = Sister.new
    subject.sister.expects(:delete)

    subject.stubs(delete: :deleted)

    subject.delete_with_children.should eq(:deleted)
  end

  it "builds a new object properly" do
    subject.id = "parent_test:123"
    child = subject.build_child age: 6

    child.should eq(subject.child)
    child.age.should eq(6)
    child.parent.should eq(subject)
  end

  describe "finding objects with children" do
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

    it "finds and returns all the proper objects" do
      bucket.expects(:get).with(
        ["parent:1", "parent:2", 'child:1', 'child:2'],
        quiet: true,
        extended: true
      ).returns({
        "parent:1" => [{name: "abc"}, 0, :cas],
        "child:2" => [{age: 5}, 0, :cas],
        "parent:2" => [{name: "def"}, 0, :cas],
        "child:1" => [{age: 7}, 0, :cas]
      })

      objects = subject.find_all_with_children(["parent:1", "parent:2"])
      objects.size.should eq(2)
      
      objects.first.id.should eq("parent:1")
      objects.first.name.should eq("abc")
      objects.first.child.id.should eq("child:1")
      objects.first.child.age.should eq(7)

      objects.last.id.should eq("parent:2")
      objects.last.name.should eq('def')
      objects.last.child.id.should eq("child:2")
      objects.last.child.age.should eq(5)
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
