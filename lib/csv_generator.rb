# frozen_string_literal: true

require 'csv'

# Handles CSV file generation for power flow analysis results
class CsvGenerator
  def initialize(results, time)
    @results = results
    @time = time
    @num_of_buses = results[:num_of_buses]
    @types = results[:types]
    @v_data = results[:v_data]
    @d_data = results[:d_data]
    @p_data = results[:p_data]
    @q_data = results[:q_data]
    @del_degree = results[:del_degree]
    @z = results[:z]
    @p_injection = results[:p_injection]
    @q_injection = results[:q_injection]
    @power_generated = results[:power_generated]
    @reactive_generated = results[:reactive_generated]
    @totals = results[:totals]
  end

  def generate_csv
    ensure_results_directory_exists
    filename = "results/PowerFlowAnalysis-NR-#{@time}.csv"
    
    CSV.open(filename, 'wb') do |csv|
      write_bus_summary_section(csv)
      write_detailed_analysis_section(csv)
      write_line_flows_section(csv)
    end
    
    filename
  end

  private

  def ensure_results_directory_exists
    Dir.mkdir('results') unless Dir.exist?('results')
  end

  def write_bus_summary_section(csv)
    csv << ['Bus Number', 'Type', 'V', 'D', 'P', 'Q']

    @num_of_buses.times do |bus|
      new_line = [bus + 1]
      new_line.push(@types[bus])
      new_line.push(@v_data[bus])
      new_line.push(@d_data[bus])
      new_line.push(@p_data[bus])
      new_line.push(@q_data[bus])
      csv << new_line
    end
  end

  def write_detailed_analysis_section(csv)
    csv << []
    csv << ['Newton Raphson Load Flow Analysis']
    csv << ['Bus #', 'V (pu)', 'Angle (degree)', 'Injection MW', 'Injection MVar', 
            'Generation MW', 'Generation MVar', 'Load MW', 'Load MVar']

    @num_of_buses.times do |i|
      new_line = [i + 1]
      new_line.push(@v_data[i])
      new_line.push(@del_degree[i])
      new_line.push(@p_injection[i])
      new_line.push(@q_injection[i])
      new_line.push(@power_generated[i])
      new_line.push(@reactive_generated[i])
      new_line.push(@results[:pl_data][i])
      new_line.push(@results[:ql_data][i])
      csv << new_line
    end

    write_totals_row(csv)
  end

  def write_totals_row(csv)
    new_line = ['Total']
    new_line.push('')
    new_line.push('')
    new_line.push(@totals[:pTotal])
    new_line.push(@totals[:qTotal])
    new_line.push(@totals[:pgTotal])
    new_line.push(@totals[:qgTotal])
    new_line.push(@totals[:plTotal])
    new_line.push(@totals[:qlTotal])
    csv << new_line
  end

  def write_line_flows_section(csv)
    csv << []
    csv << ['Line Flows and Losses']
    csv << ['From Bus', 'To Bus', 'P MW', 'Q MVar', 'From Bus', 'To Bus', 
            'P MW', 'Q MVar', 'Line Loss MW', 'Line Loss MVar']

    @z.each do |row|
      new_line = [row[0]]
      new_line.push(row[1])
      new_line.push(row[2])
      new_line.push(row[3])
      new_line.push(row[1])
      new_line.push(row[0])
      new_line.push(row[6])
      new_line.push(row[7])
      new_line.push(row[8])
      new_line.push(row[9])
      csv << new_line
    end

    write_line_losses_total(csv)
  end

  def write_line_losses_total(csv)
    new_line = ['Total Loss']
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push('')
    new_line.push(@results[:line_loss_1])
    new_line.push(@results[:line_loss_2])
    csv << new_line
  end
end 