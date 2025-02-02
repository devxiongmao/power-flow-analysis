function buildSchematicFromCSV(maxNumBuses, maxNumLines) {
	for (let i = 1; i <= maxNumBuses; i++) {
	  changeBusType(`bus-selector-${i}`, `bus-img-${i}`);
	}
  
	for (let i = 1; i <= maxNumLines; i++) {
	  buildLines(i);
	}
  }
  