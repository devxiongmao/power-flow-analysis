function buildLines(lineNum){
  var row = document.getElementById('schematic-line-' + lineNum);
  var entryNum1 = lineNum * 6 - 5;
  var entryNum2 = entryNum1 + 1;

  var fromBus = parseInt(document.getElementById('line-entry-' + entryNum1).value, 10);
  var toBus = parseInt(document.getElementById('line-entry-' + entryNum2).value, 10);
  var startPlaced = false;

  if(!isNaN(fromBus) && !isNaN(toBus)){
  	for (var j = 0, col; col = row.cells[j]; j++) {
	  if((j + 1) == fromBus || (j + 1) == toBus){
	    if(startPlaced){
	 	  col.innerHTML = '<img width="150px" src="Right-connector.png">';
	 	  startPlaced = false;
	 	}else{
	 	  col.innerHTML = '<img width="150px" src="Left-connector.png">';
	 	  startPlaced = true;
	 	}
	  }else{
	  	if(startPlaced){
	  	  col.innerHTML = '<img width="150px" src="Jump-connector.png">';
	   	}else{
		  col.innerHTML = '<img width="150px" src="No-connect.png">';
	   	}
  	  }
	}   
  }else{
  	for (var j = 0, col; col = row.cells[j]; j++) {
	  col.innerHTML = '<img width="150px" src="No-connect.png">';
	}   
  }
}