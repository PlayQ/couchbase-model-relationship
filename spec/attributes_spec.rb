require 'spec_helper'

require 'couchbase/model'
require 'couchbase/model/attributes'

describe "Attributes" do
  let(:klass) do
    Class.new(Couchbase::Model) do

      attribute :abc
    end
  end
  
  subject { klass.new }

  it "should have a setter" do
    subject.should respond_to(:abc=)
  end

  it "should have a getter" do
    subject.should respond_to(:abc)
  end

  it "should set the variable" do
    subject.abc = 1
    subject.read_attribute('abc').should eq(1)
  end

  it "should read the variable" do
    subject.write_attribute("abc", 1)
    subject.abc.should eq(1)
  end
end
