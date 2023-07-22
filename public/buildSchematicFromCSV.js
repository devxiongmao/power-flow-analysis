function buildSchematicFromCSV(maxNumBuses, maxNumLines){
	var i = 1;

	while(i <= maxNumBuses){
		changeBusType("bus-selector-" + i, "bus-img-" + i);
		i = i + 1;
	}

	i = 1;
	while(i <= maxNumLines){
		buildLines(i);
		i = i + 1;
	}
}