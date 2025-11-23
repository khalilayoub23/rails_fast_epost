module RatingsHelper
  def display_rating(score, precision: 2)
    return "N/A" if score.nil? || score.zero?

    number_with_precision(score, precision: precision)
  end
end
