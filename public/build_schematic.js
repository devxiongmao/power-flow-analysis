function buildSchematic() {
	const tbl = document.getElementById("schematic");
	if (!tbl) return; 
  
	Array.from(tbl.rows).forEach((row, index) => {
	  createCell(row.insertCell(row.cells.length), index, "col");
	});
  }
  