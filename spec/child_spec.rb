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
      let(:collider) { ChildMergeTest.new(parent: parent) }
      let(:bucket) { stub }

      before do
        parent.id = "parent:#{Time.now.to_i}"
        ChildMergeTest.stubs(bucket: bucket)
      end

      it "just fails if no merge method" do
        bucket.expects(:add).raises(Couchbase::Error::KeyExists)
        ChildTest.stubs(bucket: bucket)

        expect { subject.save }.to raise_error(Couchbase::Error::KeyExists)
      end
      
      it "just fails with no parent" do
        bucket.expects(:add).raises(Couchbase::Error::KeyExists)

        collider.parent = nil
        collider.expects(:on_key_exists_merge_from_db!).never

        expect { collider.save }.to raise_error(Couchbase::Error::KeyExists)
      end

      it "just fails with a parent and a non-parent derived id" do
        collider.instance_variable_set(:@id, "abc123:1234")
        bucket.expects(:add).raises(Couchbase::Error::KeyExists)
        collider.expects(:on_key_exists_merge_from_db!).never

        expect { collider.save }.to raise_error(Couchbase::Error::KeyExists)
      end

      # These should really exercise a real backend
      it "retries if mergable" do
        seq = sequence("collision")
        bucket.expects(:add).raises(Couchbase::Error::KeyExists).in_sequence(seq)
        bucket.expects(:add).returns(true).in_sequence(seq)

        collider.expects(:on_key_exists_merge_from_db!)

        expect { collider.save }.to_not raise_error
        collider.should be_persisted
      end

      it "fails is merging fails" do
        bucket.expects(:add).raises(Couchbase::Error::KeyExists)

        collider.expects(:on_key_exists_merge_from_db!).raises(ArgumentError)
        
        expect { collider.save }.to raise_error(ArgumentError)
      end

      it "only retries once" do
        bucket.expects(:add).raises(Couchbase::Error::KeyExists).twice

        collider.expects(:on_key_exists_merge_from_db!)

        expect { collider.save }.to raise_error(Couchbase::Error::KeyExists)
      end
    end
  end
end
