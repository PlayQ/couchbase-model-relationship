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
  child :dont_load, auto_load: false
end

class InheritanceTest < ParentTest
end

class AutoSaveTest < Couchbase::Model
  include ActiveModel::Validations

  attribute :name
  validates_length_of :name, maximum: 5

  child :child, auto_save: true
  child :brother, auto_delete: true
end

class MultipleChildTest < Couchbase::Model
  children :brother, :sister
end

class InvalidTest < Couchbase::Model
  include ActiveModel::Validations

  attribute :name
  validates_length_of :name, maximum: 5
  child :brother
end

describe "parent" do
  subject { ParentTest.new }

  it "has a setter" do
    subject.should respond_to(:child=)
  end

  it "has a getter" do
    subject.should respond_to(:child)
  end

  it "passes on it's children" do
    InheritanceTest.child_association_names.should eq(ParentTest.child_association_names)
  end

  context "the getter" do
    let(:association) { ParentTest.child_association_for :child }

    it "returns the value is present" do
      subject.child = (brother = Brother.new)
      subject.child.should eq(brother)
    end

    it "tries to load from the db if not loaded" do
      subject.expects(:build_child).never
      association.expects(:load).returns((child = Child.new)).once

      subject.child.should eq(child)
      subject.child.should eq(child)
    end

    it "builds a new child if child doesn't exist in the db" do
      association.expects(:load).returns(nil).once

      subject.child.should be_a(Child)
      subject.child.should be_a(Child)
    end
  end

  it "can reload itself and all it's children" do
    subject.child = stub(reload: true)
    subject.dont_load = stub(reload: true)
    subject.expects(:reload)

    subject.reload_all
  end

  it "knows if the child is loaded or not" do
    subject.should_not be_child_loaded
    subject.send :child_loaded!
    subject.should be_child_loaded
  end

  it "marks the child loaded when set" do
    subject.should_not be_child_loaded
    subject.child = Child.new
    subject.should be_child_loaded
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

  it "doesn't save children if the main object isn't valid" do
    subject = InvalidTest.new
    subject.brother = Brother.new
    subject.brother.stubs(changed?: true)
    subject.brother.expects(:save).never

    subject.name = "123456"

    subject.save_with_children
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

  it "doesn't auto-save children if we fail to save" do
    subject = AutoSaveTest.new name: "Test abc"
    subject.child = Child.new age: 5
    subject.brother = Brother.new

    subject.child.expects(:save_if_changed).never
    subject.brother.expects(:save_if_changed).never

    subject.save
  end

  it "auto-deletes children marked as auto-delete" do
    subject = AutoSaveTest.new name: "Test"
    subject.child = Child.new age: 5
    subject.brother = Brother.new

    subject.stubs(delete_without_autodelete_children: true)

    subject.child.expects(:delete).never
    subject.brother.expects(:delete)

    subject.delete
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

  it "returns the loaded children" do
    subject = MultipleChildTest.new

    subject.brother = brother = Brother.new

    subject.loaded_children.should eq([brother])
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
      parent.should_not be_changed

      parent.child.age.should eq(5)
      parent.child.should_not be_changed
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

    it "marks all children as loaded even if they're not found" do
      bucket.expects(:get).with(
        ["parent:1", "child:1"],
        quiet: true,
        extended: true
      ).returns({
        "parent:1" => [{name: "abc"}, 0, :cas],
      })

      parent = subject.find_with_children("parent:1")
      parent.should be_child_loaded
      parent.child.should be_new
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
    end
  end
end
