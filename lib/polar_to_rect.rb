class PolarToRectangular
	def main(v_data, d_data)
		polar = []

		num_of_buses = v_data.size

		num_of_buses.times do |i|
			polar[i] = [0,0] unless polar[i]
		end

		v_data.each_with_index do |value, i|
			polar[i][0] = value*Math.cos(d_data[i])
			polar[i][1] = value*Math.sin(d_data[i])
		end

		return polar 
	end
end