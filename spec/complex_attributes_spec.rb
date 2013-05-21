require 'spec_helper'

class ComplexTest < Couchbase::Model
  class Child
    attr_accessor :name

    def self.json_create(args)
      new(*args['parameters'])
    end

    def initialize(name)
      self.name = name
    end

    def to_json(*args)
      {
        'json_class' => self.class.name,
        'parameters' => [name]
      }.to_json(*args)
    end
  end

  attribute :array, default: []
  array_attribute :array
end

describe "complex attributes" do
  describe "array attributes" do
    subject { ComplexTest.new }

    let(:raw) do
      {
        'json_class' => 'ComplexTest::Child',
        'parameters' => ['abc']
      }.to_json
    end

    let(:object) { ComplexTest::Child.new('exist') }

    it "sets values properly" do
      subject.array = [raw, object]
      subject.array.all? {|c| ComplexTest::Child === c }.should be_true

      subject.array.map(&:name).should eq(%w(abc exist))
    end
  end
end
