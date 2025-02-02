function buildLines(lineNum) {
	const row = document.getElementById(`schematic-line-${lineNum}`);
	if (!row) return; // Exit if row is not found
  
	const entryNum1 = lineNum * 6 - 5;
	const entryNum2 = entryNum1 + 1;
  
	const fromBus = parseInt(document.getElementById(`line-entry-${entryNum1}`)?.value, 10);
	const toBus = parseInt(document.getElementById(`line-entry-${entryNum2}`)?.value, 10);
  
	if (isNaN(fromBus) || isNaN(toBus)) {
	  resetRow(row);
	  return;
	}
  
	let startPlaced = false;
  
	Array.from(row.cells).forEach((col, index) => {
	  const cellNum = index + 1;
	  if (cellNum === fromBus || cellNum === toBus) {
		col.innerHTML = startPlaced
		  ? '<img width="150px" src="Right-connector.png">'
		  : '<img width="150px" src="Left-connector.png">';
		startPlaced = !startPlaced;
	  } else {
		col.innerHTML = startPlaced
		  ? '<img width="150px" src="Jump-connector.png">'
		  : '<img width="150px" src="No-connect.png">';
	  }
	});
  }
  
  function resetRow(row) {
	Array.from(row.cells).forEach(col => {
	  col.innerHTML = '<img width="150px" src="No-connect.png">';
	});
  }
  