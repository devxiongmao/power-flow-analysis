function buildSchematic(){
	for(;;){
		var busTypes = document.getElementsByClassName("bus-select");
		var busVoltages = document.getElementsByClassName("bus-voltage");
		var busAngles = document.getElementsByClassName("bus-angle");
		var busPValues = document.getElementsByClassName("bus-p");
		var busQValues = document.getElementsByClassName("bus-q");

		var tbl = document.getElementById('schematic'), // table reference
        i;
	    // open loop for each row and append cell
	    for (i = 0; i < tbl.rows.length; i++) {
	        createCell(tbl.rows[i].insertCell(tbl.rows[i].cells.length), i, 'col');
	    }
	}
}