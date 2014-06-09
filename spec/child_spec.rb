require 'spec_helper'

class ChildTest < Couchbase::Model
  has_parent
end

class ChildMergeTest < Couchbase::Model
  has_parent

  def on_key_exists_merge_from_db!
  end
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

    describe "with collisions" do

      before(:all) do
        @mock = start_mock
        bucket = Couchbase.connect(:hostname => @mock.host, :port => @mock.port)

        ChildMergeTest.bucket = bucket
        ChildTest.bucket = bucket
        ChildTestParent.bucket = bucket
      end

      after(:all) do
        stop_mock @mock

        ChildMergeTest.bucket = nil
        ChildTest.bucket = nil
        ChildTestParent.bucket = nil
      end

      let(:collider) { ChildMergeTest.new(parent: parent) }
      let(:existing) { ChildMergeTest.new(parent: parent).save! }

      before do
        parent.id = "parent:#{Time.now.to_f}"

        subject.parent = parent
      end

      it "just fails if no merge method" do
        subject.class.new(parent: parent).save!

        expect { subject.save }.to raise_error(Couchbase::Error::KeyExists)
      end
      
      it "just fails with no parent" do
        collider.parent = nil
        collider.instance_variable_set(:@id, existing.id)
        collider.expects(:on_key_exists_merge_from_db!).never

        expect { collider.save }.to raise_error(Couchbase::Error::KeyExists)
      end

      it "just fails with a parent and a non-parent derived id" do
        ChildMergeTest.bucket.add("abc-123" => "boo")

        collider.instance_variable_set(:@id, "abc-123")
        collider.expects(:on_key_exists_merge_from_db!).never

        expect { collider.save }.to raise_error(Couchbase::Error::KeyExists)
      end

      # These should really exercise a real backend
      it "retries if mergable" do
        existing

        collider.expects(:on_key_exists_merge_from_db!)

        expect { collider.save }.to_not raise_error
        collider.should be_persisted
      end

      it "fails is merging fails" do
        existing

        collider.expects(:on_key_exists_merge_from_db!).raises(ArgumentError)
        
        expect { collider.save }.to raise_error(ArgumentError)
      end

      it "raises if save after merge fails" do
        existing

        collider.expects(:on_key_exists_merge_from_db!)
        collider.stubs(:save).raises(RuntimeError)

        expect { collider.create }.to raise_error(RuntimeError)
      end
    end
  end
end
