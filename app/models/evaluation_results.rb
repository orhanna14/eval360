class EvaluationResults

  def initialize(participant)
    @participant = participant
  end

  def histogram_for_q(question_id)
    histogram = []
    0.upto(10) { histogram.push(0) }
    if peer_evaluations.any?
      a = peer_evaluations.first.answers.find_by(question_id: question_id)
      a_index = peer_evaluations.first.answers.index(a)
      peer_evaluations.each do |pe|
        response = pe.answers[a_index].numeric_response
        histogram[response] += 1 unless response.nil? || response.zero?
      end
    end
    return histogram
  end

  def self_score_for_q(question_id)
    self_evaluation.answers.find_by(question_id: question_id).numeric_response
  end

  def mean_score_for_q(question_id)
    answers = []
    peer_evaluations.each do |pe|
      answer = pe.answers.find_by(question_id: question_id)
      if answer && answer.numeric_response && !answer.numeric_response.zero?
        answers.push answer.numeric_response
      end
    end

    answers.any? ? answers.sum.to_f/answers.length : nil
  end

  def mean_score_for_s(section)
    scores = []
    section.questions.each do |question|
      mean = mean_score_for_q(question.id)
      scores <<  mean if mean
    end
    scores.any? ? scores.sum.to_f/scores.length : nil
  end

  def quartile_rank( score, all_scores )
    lower_scores = all_scores.select{ |value| !value.nil? && value < score }.size
    return 4 if lower_scores.zero?
    quartile_size = all_scores.size.to_f / 4.0
    case
      when lower_scores > quartile_size * 3
        1
      when lower_scores > quartile_size * 2
        2
      when lower_scores > quartile_size
        3
      else 
        4 
      end
  end

  def rw_quartile(question_id)
    rw_dataset = Answer.peer_assessment_scores(question_id, @participant.id) 
    question = Question.find(question_id)
    if question.legacy_tag
      @legacy_values = LegacyMeanScores.mean_scores question.legacy_tag
      rw_dataset +=  @legacy_values if @legacy_values
    end
    return 0 if rw_dataset.empty? 
    eval_mean = mean_score_for_q(question_id)
    quartile_rank eval_mean, rw_dataset
  end

  def text_answers_for_q(question_id)
    answers = peer_evaluations.map { |pe| pe.answers.find_by(question_id: question_id) }
    responses = []
    answers.each do |a|
      unless a.text_response.nil? || a.text_response.blank?
        responses << a.text_response
      end
    end
    responses
  end

  def self_answer_for_q(question_id)
    self_evaluation.answers.where(question_id: question_id).first.text_response
  end

  def get_top_8
    get_sorted_scores.shift(8)
  end

  def get_bottom_8
    get_sorted_scores.pop(8)
  end

  def get_top_4
    get_sorted_scores.shift(4)
  end

  def get_bottom_4
    get_sorted_scores.pop(4)
  end


  private

  def self_evaluation
    @participant.self_evaluation
  end

  def peer_evaluations
    @participant.peer_evaluations
  end

  def get_sorted_scores
    questions = @participant.training.questionnaire.numeric_questions
    results = []
    questions.each_with_index do |q,i|
      info = {
        position: i + 1,
        mean_score: mean_score_for_q(q.id),
        description: q.self_description
      }
      results.push(info) if info['mean_score']
    end
    results.sort! { |a,b| b[:mean_score] <=> a[:mean_score] }
  end

end
