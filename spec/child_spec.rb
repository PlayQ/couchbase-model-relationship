require 'spec_helper'

class ChildTest < Couchbase::Model
  has_parent
end

class ChildTestParent < Couchbase::Model
  child :child_test
end

describe "children" do
  let(:parent) { ChildTestParent.new }
  subject { ChildTest.new }

  it "allows you to set the parent" do
    subject.should respond_to(:parent=)

    subject.parent = parent
    subject.parent.should eq(parent)
  end

  describe "creating" do
    it "inherits the UUID of the parent" do
      parent.id = "child_test_parent:1234"
      ChildTest.stubs(bucket: stub(add: true))

      subject.parent = parent
      subject.create

      subject.id.should eq("child_test:1234")
    end
  end
end
