require 'spec_helper'

describe Couchbase::Model::DeepCopier do
  it "hands uncloneable objects" do
    source = 1
    copy = described_class.new(source).copy

    source.should eq(1)
    copy.should eq(1)
  end
  it "properly clones a normal object" do
    source = "abc"
    copy = described_class.new(source).copy

    source.should eq(copy)
    source.object_id.should_not eq(copy.object_id)
  end

  it "properly clones an array" do
    source = []
    copy = described_class.new(source).copy
    source.push :a

    source.should_not eq(copy)
    copy.should eq([])
  end

  it "properly clones nested arrays" do
    source = [[]]
    copy = described_class.new(source).copy
    source.last.push :a

    source.should_not eq(copy)
    copy.should eq([[]])
  end

  it "properly clones a hash" do
    source = {}
    copy = described_class.new(source).copy
    source[:key] = :val

    source.should_not eq(copy)
    copy.should eq({})
  end

  it "properly clones a nested hash" do
    source = {key: []}
    copy = described_class.new(source).copy

    source[:key1] = 'a'
    source[:key].push 'b'

    source.should_not eq(copy)
    copy.should eq({key: []})
  end


end
