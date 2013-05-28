require 'spec_helper'

class DirtyTest < Couchbase::Model
  attribute :name
  attribute :complex
end

describe "Dirty" do
  subject { DirtyTest.new }

  it "should mark the fields as dirty" do
    subject.name = 'abc'
    subject.should be_name_changed
  end

  it "should mark complex fields" do
    inner = []
    outer = [inner]

    subject.complex = outer
    subject.send :clean!

    subject.complex_will_change!
    subject.complex[0].push 'abc'

    subject.should be_complex_changed
    subject.complex.should eq([['abc']])
    subject.complex_was.should eq([[]])
  end

  it "should not mark the field dirty when the value is the same" do
    subject.name = "abc"
    subject.send :clean!

    subject.name = "abc"

    subject.should_not be_name_changed
  end

  it "doesn't mark any fields as dirty when the model is loaded" do
    DirtyTest.stubs(bucket: stub)
    DirtyTest.bucket.expects(:get).with(['abc123'], quiet: false, extended: true).returns({'name' => "Bob"}, {}, 123)

    DirtyTest.find('abc123').should_not be_changed
  end

  describe "creating" do
    describe "successfully" do
      before do
        subject.stubs(create_without_dirty: true)
        subject.name = "creating"
        subject.create
      end

      it "captures changes" do
        subject.name.should eq("creating")
        subject.should_not be_name_changed
        subject.previous_changes['name'].should eq([nil, 'creating'])
      end

      it "clears current changes" do
        subject.changes.should be_blank
      end
    end

    describe "failing" do
      before do
        subject.stubs(create_without_dirty: false)
        subject.name = "creating"
        subject.create
      end

      it "doesn't capture changes" do
        subject.previous_changes.should be_blank
      end

      it "doesn't clear current changes" do
        subject.changed.should eq(["name"]) 
      end
    end
  end

  describe "saving" do
    it "doesn't saves if not changed on request" do
      subject.stubs(changed?: false)
      subject.expects(:save).never

      subject.save_if_changed
    end

    it "saves if changed on request" do
      subject.stubs(changed?: true)
      subject.expects(:save)

      subject.save_if_changed
    end

    describe "successfully" do
      before do
        subject.stubs(save_without_dirty: true)
        subject.name = "save"
        subject.id = 123
        subject.save
      end

      it "captures changes" do
        subject.name.should eq("save")
        subject.should_not be_name_changed
        subject.previous_changes['name'].should eq([nil, 'save'])
      end

      it "clears current changes" do
        subject.changes.should be_blank
      end
    end

    describe "failing" do
      before do
        subject.stubs(save_without_dirty: false)
        subject.name = "save"
        subject.id = 123
        subject.save
      end

      it "doesn't capture changes" do
        subject.previous_changes.should be_blank
      end

      it "doesn't clear current changes" do
        subject.changed.should eq(["name"]) 
      end
    end
  end
end
