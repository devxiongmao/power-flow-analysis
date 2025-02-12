# frozen_string_literal: true

# Creates the YBus for use during the processing
class YBusCreator
  Line = Struct.new(:from, :to, :resistance, :reactance, :ground_admittance, :tap_setting, :y)

  def initialize(_num_of_buses, num_of_lines, data)
    @lines = Array.new(num_of_lines) { |i| parse_line_data(i, data) }
  end

  def return_from_bus_list
    @lines.map(&:from)
  end

  def return_to_bus_list
    @lines.map(&:to)
  end

  def create_y_bus(num_of_buses)
    y_bus = Array.new(num_of_buses) { Array.new(num_of_buses, [ 0, 0 ]) }

    @lines.each do |line|
      update_off_diagonal(y_bus, line)
    end

    num_of_buses.times do |m|
      @lines.each { |line| update_diagonal(y_bus, m, line) }
    end

    y_bus
  end

  private

  def parse_line_data(i, data)
    from = data["from-#{i + 1}"].to_f - 1
    to = data["to-#{i + 1}"].to_f - 1
    resistance = data["line-resistance-#{i + 1}"].to_f
    reactance = data["line-reactance-#{i + 1}"].to_f
    ground_admittance = data["ground-admittance-#{i + 1}"].to_f
    tap_setting = data["tap-setting-#{i + 1}"].to_f

    y = calculate_admittance(resistance, reactance)

    Line.new(from, to, resistance, reactance, ground_admittance, tap_setting, y)
  end

  def calculate_admittance(resistance, reactance)
    denominator = resistance**2 + reactance**2
    [ resistance / denominator, -reactance / denominator ]
  end

  def update_off_diagonal(y_bus, line)
    y_bus[line.from][line.to] = [
      y_bus[line.from][line.to][0] - line.y[0] / line.tap_setting,
      y_bus[line.from][line.to][1] - line.y[1] / line.tap_setting
    ]

    y_bus[line.to][line.from] = y_bus[line.from][line.to]
  end

  def update_diagonal(y_bus, m, line)
    if line.from == m
      y_bus[m][m] = [
        y_bus[m][m][0] + line.y[0] / (line.tap_setting**2),
        y_bus[m][m][1] + line.y[1] / (line.tap_setting**2) + line.ground_admittance
      ]
    elsif line.to == m
      y_bus[m][m] = [
        y_bus[m][m][0] + line.y[0],
        y_bus[m][m][1] + line.y[1] + line.ground_admittance
      ]
    end
  end
end
