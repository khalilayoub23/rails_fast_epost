class CostCalculator
  def initialize(task, letters_count: 1)
    @task = task
    @route_distance = @task.distance
    @letters_count = letters_count
  end

  def total_cost
    return 0 unless distance_available?

    fuel_cost + agent_earnings + constants[:waiting_time_cost] + constants[:parking_costs] + constants[:highway_costs] + priority_cost + special_costs + customer_location_cost - discount
  end

  def cost_details
    return { "error" => "Missing distance" } unless distance_available?

    {
      "Fuel Cost" => fuel_cost,
      "Agent Earnings" => {
        "Travel Time (hours)" => travel_time,
        "Hourly Rate" => adjusted_hourly_rate,
        "Total Earnings" => agent_earnings
      },
      "Waiting Time Cost" => constants[:waiting_time_cost],
      "Parking Costs" => constants[:parking_costs],
      "Highway Costs" => constants[:highway_costs],
      "Priority Cost" => {
        "Task Priority" => @task.priority,
        "Cost" => priority_cost
      },
      "Special Costs" => special_costs,
      "Customer Location Cost" => customer_location_cost,
      "Discount" => discount,
      "Total Cost" => total_cost
    }
  end

  private

  def constants
    @constants ||= {
      cost_per_km: env_numeric("COST_PER_KM", 1.0),
      km_per_litre: env_numeric("KM_PER_LITRE", 10.0),
      average_speed: env_numeric("AVERAGE_SPEED_KMPH", 40.0),
      hourly_rate: env_numeric("AGENT_HOURLY_RATE", 25.0),
      waiting_time_cost: env_numeric("WAITING_TIME_COST", 0.0),
      parking_costs: env_numeric("PARKING_COSTS", 0.0),
      highway_costs: env_numeric("HIGHWAY_COSTS", 0.0),
      special_costs: env_numeric("SPECIAL_COSTS", 0.0),
      customer_location_cost: env_numeric("CUSTOMER_LOCATION_COST", 0.0),
      discount_per_letter: env_numeric("DISCOUNT_PER_LETTER", 0.0)
    }
  end

  def env_numeric(key, default)
    val = ENV.fetch(key, nil)
    return default if val.nil?

    Float(val)
  rescue ArgumentError, TypeError
    default
  end

  def distance_available?
    @route_distance.present? && @route_distance.to_f.positive?
  end

  def fuel_cost
    return 0 unless distance_available?

    (@route_distance.to_f * 2 * constants[:cost_per_km]) / constants[:km_per_litre]
  end

  def travel_time
    return 0 unless distance_available?

    (@route_distance.to_f * 2) / constants[:average_speed].to_f
  end

  def adjusted_hourly_rate
    @task.priority == "high" ? constants[:hourly_rate] * 3 : constants[:hourly_rate]
  end

  def agent_earnings
    travel_time * adjusted_hourly_rate
  end

  def special_costs
    constants[:special_costs]
  end

  def customer_location_cost
    constants[:customer_location_cost]
  end

  def priority_cost
    @task.priority == "high" ? (fuel_cost + agent_earnings) : 0
  end

  def discount
    @letters_count * constants[:discount_per_letter]
  end
end
