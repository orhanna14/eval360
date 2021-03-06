require 'rails_helper'

RSpec.describe Question, :type => :model do
  expect_it { to belong_to :section }
  expect_it { to have_many :answers }
  expect_it { to validate_presence_of :answer_type }

  describe ".generate_from_parsed_yaml" do
    it "creates a question" do
      parsed_yaml = ["range1"]
      parsed_yaml << {"text"=>"Overall, performs the primary tasks for which they are responsible at the highest standards of excellence.", "self_text"=>"Overall, I perform the primary tasks for which I am responsible at the highest standards of excellence.", "legacy_tag"=>"performs_tasks"}
      question = Question.generate_from_parsed_yaml(parsed_yaml)
      expect(question).to be_instance_of(Question)
    end
  end

  describe "#numeric?" do
    it "returns true if answer type is numeric" do
      question = FactoryBot.create(:question)
      expect(question.numeric?).to be true
    end

    it "returns false if answer type is text" do
      question = FactoryBot.create(:text_question)
      expect(question.numeric?).to be false
    end

  end

end
