class Flashcard < ApplicationRecord
  belongs_to :deck
  has_one :user, through: :deck

  validates :front_text, :back_text, :deck, presence: true
  validates :ease_factor, numericality: { greater_than_or_equal_to: 1.3 }
  validates :interval, :review_count, numericality: { greater_than_or_equal_to: 0 }

  # Scope for cards due for review
  scope :due, -> { where("next_review_at <= ?", Date.current) }
  scope :due_today, -> { where(next_review_at: Date.current) }
  scope :overdue, -> { where("next_review_at < ?", Date.current) }

  # SM-2 algorithm implementation
  # quality: 0-5 rating (0-2 = fail, 3-5 = pass)
  # 0 = complete blackout
  # 1 = wrong, but recognized after seeing answer
  # 2 = wrong, but easy to recall after seeing answer
  # 3 = correct with serious difficulty
  # 4 = correct with some hesitation
  # 5 = perfect response
  def record_review(quality)
    raise ArgumentError, "Quality must be 0-5" unless (0..5).include?(quality)

    self.review_count += 1
    self.last_reviewed_at = Time.current

    if quality < 3
      # Failed - reset interval
      self.interval = 0
      self.next_review_at = Date.current
    else
      # Passed - calculate new interval
      self.interval = calculate_next_interval
      self.next_review_at = Date.current + interval.days
    end

    self.ease_factor = calculate_new_ease_factor(quality)

    save!
  end

  def due?
    next_review_at <= Date.current
  end

  def due_today?
    next_review_at == Date.current
  end

  def overdue?
    next_review_at < Date.current
  end

  def days_until_review
    (next_review_at - Date.current).to_i
  end

  private

  def calculate_next_interval
    case review_count
    when 1
      1 # 1 day for first successful review
    when 2
      6 # 6 days for second successful review
    else
      # otherwise use the ease factor
      (interval * ease_factor).round
    end
  end

  def calculate_new_ease_factor(quality)
    # SM-2 ease factor formula
    new_ef = ease_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    
    # Minimum ease factor is 1.3
    [new_ef, 1.3].max
  end
end
