# frozen_string_literal: true

class YBusCreator
  def initialize(_num_of_buses, num_of_lines, data)
    @from_bus_list = []
    @to_bus_list = []
    @resistance_list = []
    @reactance_list = []
    @ground_admittance = []
    @tap_setting = []

    num_of_lines.times do |i|
      @from_bus_list.push(data["from-#{i + 1}"].to_f - 1)
      @to_bus_list.push(data["to-#{i + 1}"].to_f - 1)
      @resistance_list.push(data["line-resistance-#{i + 1}"].to_f)
      @reactance_list.push(data["line-reactance-#{i + 1}"].to_f)
      @ground_admittance.push(data["ground-admittance-#{i + 1}"].to_f)
      @tap_setting.push(data["tap-setting-#{i + 1}"].to_f)
    end

    @y = []
    num_of_lines.times do |i|
      deno = ((@resistance_list[i]**2) + (@reactance_list[i]**2))
      @y[i] = if (@reactance_list[i]).zero?
                [(@resistance_list[i] / deno), (@reactance_list[i] / deno)]
              else
                [(@resistance_list[i] / deno), (-1 * @reactance_list[i] / deno)]
              end
    end
  end

  def return_from_bus_list
    @from_bus_list
  end

  def return_to_bus_list
    @to_bus_list
  end

  def create_y_bus(num_of_buses, num_of_lines)
    #### BUILD THE Y BUS MATRIX ####
    y_bus = []
    num_of_buses.times do |i| # Initialize empty nxn Y Bus matrix
      y_bus[i] = [] unless y_bus[i]
      num_of_buses.times do |j|
        y_bus[i][j] = [0, 0]
      end
    end

    num_of_lines.times do |i|
      y_bus[@from_bus_list[i]][@to_bus_list[i]][0] =
        y_bus[@from_bus_list[i]][@to_bus_list[i]][0] - @y[i][0] / @tap_setting[i]
      y_bus[@from_bus_list[i]][@to_bus_list[i]][1] =
        y_bus[@from_bus_list[i]][@to_bus_list[i]][1] - @y[i][1] / @tap_setting[i]
      y_bus[@to_bus_list[i]][@from_bus_list[i]] = y_bus[@from_bus_list[i]][@to_bus_list[i]]
    end

    num_of_buses.times do |m|
      num_of_lines.times do |n|
        if @from_bus_list[n] == m
          y_bus[m][m][0] = y_bus[m][m][0] + @y[n][0] / (@tap_setting[n]**2)
          y_bus[m][m][1] = y_bus[m][m][1] + @y[n][1] / (@tap_setting[n]**2) + @ground_admittance[n]
        elsif @to_bus_list[n] == m
          y_bus[m][m][0] = y_bus[m][m][0] + @y[n][0]
          y_bus[m][m][1] = y_bus[m][m][1] + @y[n][1] + @ground_admittance[n]
        end
      end
    end

    y_bus
  end
end
