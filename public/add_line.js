function addLine(type){
    var busNum = document.getElementsByClassName("bus-num").length;
    var lineNum = document.getElementsByClassName("line-num").length;
    var newrow = document.createElement('tr');
    if(type === 'bus'){
      var newEntryLine = '<td class="bus-num" align="center">' + (busNum + 1);
      newEntryLine = newEntryLine + '</td><td><select class="bus-select" name="type-' + (busNum + 1);
      newEntryLine = newEntryLine + '" id="bus-selector-' + (busNum + 1)+'"'; 
      newEntryLine = newEntryLine +' onchange="changeBusType(' + "'bus-selector-" + (busNum + 1)+"', 'bus-img-"+ (busNum + 1)+"');"; 
      newEntryLine = newEntryLine + '"><option value="slack">Slack Bus</option><option value="generator">Generator Bus</option><option value="load">Load Bus</option></select></td><td><input class="bus-voltage" type="text" id="entry-' + ((busNum + 1) * 8 - 7); 
      newEntryLine = newEntryLine + '" oninput="' + "populateValues('entry-"+ ((busNum + 1) * 8 - 7) +"', 'schem-"+ ((busNum + 1) * 8 - 7)  +"');" + '" name="v' + (busNum + 1); 
      newEntryLine = newEntryLine + '"></td><td><input class="bus-angle" type="text" id="entry-' + ((busNum + 1) * 8 - 6) + '" onchange="Validation(\'bus-selector-'+(busNum+1)+'\', \'entry-'+((busNum+1)*8 -7)+'\', \'entry-'+((busNum+1)*8 -6)+'\', \'entry-'+((busNum+1)*8 -5)+'\', \'entry-'+((busNum+1)*8 -4)+'\', \'entry-'+((busNum+1)*8 -3)+'\', \'entry-'+((busNum+1)*8 -2)+'\', \'entry-'+((busNum+1)*8 -1)+'\', \'entry-'+((busNum+1)*8)+'\',\''+(busNum+1)+'\')" oninput="' + "populateValues('entry-"+ ((busNum + 1) * 8 - 6) +"', 'schem-"+ ((busNum + 1) * 8 - 6) +"');" + '" name="d' + (busNum + 1); 
      newEntryLine = newEntryLine + '"></td><td><input class="bus-pgi" type="text" id="entry-' + ((busNum + 1) * 8 - 5) + '" onchange="Validation(\'bus-selector-'+(busNum+1)+'\', \'entry-'+((busNum+1)*8 -7)+'\', \'entry-'+((busNum+1)*8 -6)+'\', \'entry-'+((busNum+1)*8 -5)+'\', \'entry-'+((busNum+1)*8 -4)+'\', \'entry-'+((busNum+1)*8 -3)+'\', \'entry-'+((busNum+1)*8 -2)+'\', \'entry-'+((busNum+1)*8 -1)+'\', \'entry-'+((busNum+1)*8)+'\',\''+(busNum+1)+'\')" oninput="' + "populateValues('entry-"+ ((busNum + 1) * 8 - 5) +"', 'schem-"+ ((busNum + 1) * 8 - 5) +"');" + '" name="pg' + (busNum + 1); 
      newEntryLine = newEntryLine + '"></td><td><input class="bus-qgi" type="text" id="entry-' + ((busNum + 1) * 8 - 4) + '" onchange="Validation(\'bus-selector-'+(busNum+1)+'\', \'entry-'+((busNum+1)*8 -7)+'\', \'entry-'+((busNum+1)*8 -6)+'\', \'entry-'+((busNum+1)*8 -5)+'\', \'entry-'+((busNum+1)*8 -4)+'\', \'entry-'+((busNum+1)*8 -3)+'\', \'entry-'+((busNum+1)*8 -2)+'\', \'entry-'+((busNum+1)*8 -1)+'\', \'entry-'+((busNum+1)*8)+'\',\''+(busNum+1)+'\')" oninput="' + "populateValues('entry-"+ ((busNum + 1) * 8 - 4) +"', 'schem-"+ ((busNum + 1) * 8 - 4) +"');" + '" name="qg' + (busNum + 1); 
      newEntryLine = newEntryLine + '"></td><td><input class="bus-pli" type="text" id="entry-' + ((busNum + 1) * 8 - 3) + '" onchange="Validation(\'bus-selector-'+(busNum+1)+'\', \'entry-'+((busNum+1)*8 -7)+'\', \'entry-'+((busNum+1)*8 -6)+'\', \'entry-'+((busNum+1)*8 -5)+'\', \'entry-'+((busNum+1)*8 -4)+'\', \'entry-'+((busNum+1)*8 -3)+'\', \'entry-'+((busNum+1)*8 -2)+'\', \'entry-'+((busNum+1)*8 -1)+'\', \'entry-'+((busNum+1)*8)+'\',\''+(busNum+1)+'\')" oninput="' + "populateValues('entry-"+ ((busNum + 1) * 8 - 3) +"', 'schem-"+ ((busNum + 1) * 8 - 3) +"');" + '" name="pl' + (busNum + 1);
      newEntryLine = newEntryLine + '"></td><td><input class="bus-qli" type="text" id="entry-' + ((busNum + 1) * 8 - 2) + '" onchange="Validation(\'bus-selector-'+(busNum+1)+'\', \'entry-'+((busNum+1)*8 -7)+'\', \'entry-'+((busNum+1)*8 -6)+'\', \'entry-'+((busNum+1)*8 -5)+'\', \'entry-'+((busNum+1)*8 -4)+'\', \'entry-'+((busNum+1)*8 -3)+'\', \'entry-'+((busNum+1)*8 -2)+'\', \'entry-'+((busNum+1)*8 -1)+'\', \'entry-'+((busNum+1)*8)+'\',\''+(busNum+1)+'\')" oninput="' + "populateValues('entry-"+ ((busNum + 1) * 8 - 2) +"', 'schem-"+ ((busNum + 1) * 8 - 2) +"');" + '" name="ql' + (busNum + 1);
      newEntryLine = newEntryLine + '"></td><td><input class="bus-qmin" type="text" id="entry-' + ((busNum + 1) * 8 - 1) + '" onchange="Validation(\'bus-selector-'+(busNum+1)+'\', \'entry-'+((busNum+1)*8 -7)+'\', \'entry-'+((busNum+1)*8 -6)+'\', \'entry-'+((busNum+1)*8 -5)+'\', \'entry-'+((busNum+1)*8 -4)+'\', \'entry-'+((busNum+1)*8 -3)+'\', \'entry-'+((busNum+1)*8 -2)+'\', \'entry-'+((busNum+1)*8 -1)+'\', \'entry-'+((busNum+1)*8)+'\',\''+(busNum+1)+'\')" oninput="' + "populateValues('entry-"+ ((busNum + 1) * 8 - 1) +"', 'schem-"+ ((busNum + 1) * 8 - 1) +"');" + '" name="qmin' + (busNum + 1);
      newEntryLine = newEntryLine + '"></td><td><input class="bus-qmax" type="text" id="entry-' + ((busNum + 1) * 8) + '" onchange="Validation(\'bus-selector-'+(busNum+1)+'\', \'entry-'+((busNum+1)*8 -7)+'\', \'entry-'+((busNum+1)*8 -6)+'\', \'entry-'+((busNum+1)*8 -5)+'\', \'entry-'+((busNum+1)*8 -4)+'\', \'entry-'+((busNum+1)*8 -3)+'\', \'entry-'+((busNum+1)*8 -2)+'\', \'entry-'+((busNum+1)*8 -1)+'\', \'entry-'+((busNum+1)*8)+'\',\''+(busNum+1)+'\')" oninput="' + "populateValues('entry-"+ ((busNum + 1) * 8) +"', 'schem-"+ ((busNum + 1) * 8) +"');" + '" name="qmax' + (busNum + 1) + '"></td>';
      newEntryLine = newEntryLine + '<td class="check" id="line-' + (busNum + 1) + '"><img width="20px" src="redx.png"></img></td>';


      newrow.innerHTML = newEntryLine;
      newrow.setAttribute("id", busNum + 1);
      newrow.setAttribute("align", "center");
      var tbl = document.getElementById('schematic'), // table reference
        i;
      // open loop for each row and append cell
      for (i = 0; i < tbl.rows.length; i++) {
        var row = tbl.rows[i];
        var x = row.insertCell(tbl.rows[i].cells.length);
        var numValue = (busNum) * 8 + 1 + i;
        if (i < 8){
          x.setAttribute("id", "schem-" + numValue);
          x.setAttribute("align", "center");
          if (i == 0){
            x.innerHTML = "V:  ";
          }else if(i == 1){
            x.innerHTML = "A:  ";
          }else if(i == 2){
            x.innerHTML = "PGi:  ";
          }else if(i == 3){
            x.innerHTML = "QGi:  ";
          }else if(i == 4){
            x.innerHTML = "PLi:  ";
          }else if(i == 5){
            x.innerHTML = "QLi:  ";
          }else if(i == 6){
            x.innerHTML = "QMin:  ";
          }else if(i == 7){
            x.innerHTML = "QMax:  ";
          }
        }else {
          x.setAttribute("id", "bus-img-" + (busNum + 1));
          if (i == 8 ){
            x.setAttribute("class", "sch");
            x.innerHTML = '<img width="150px" src="Slack.png">';
          }else{
            x.setAttribute("class", "sch");
            x.innerHTML = '<img width="150px" src="No-connect.png">';
          }
        }
      }
    } else {
      var newEntryLine = '<td class="line-num" align="center">' + (lineNum + 1); 
      newEntryLine = newEntryLine +'</td><td><input type="text" name="from-' + (lineNum + 1) + '" id="line-entry-' + ((lineNum + 1) * 6 - 5) + '" oninput="buildLines('  + (lineNum + 1); 
      newEntryLine = newEntryLine + ');"></td><td><input type="text" name="to-' + (lineNum + 1) + '" id="line-entry-' + ((lineNum + 1) * 6 - 4) + '" oninput="buildLines('  + (lineNum + 1); 
      newEntryLine = newEntryLine + ');"></td><td><input type="text" name="line-resistance-' + (lineNum + 1) + '" id="line-entry-' + ((lineNum + 1) * 6 - 3) + '" oninput="buildLines('  + (lineNum + 1); 
      newEntryLine = newEntryLine + ');"></td><td><input type="text" name="line-reactance-' + (lineNum + 1) + '" id="line-entry-' + ((lineNum + 1) * 6 - 2) + '" oninput="buildLines('  + (lineNum + 1); 
      newEntryLine = newEntryLine + ');"></td><td><input type="text" name="ground-admittance-' + (lineNum + 1) + '" id="line-entry-' + ((lineNum + 1) * 6 - 1) + '" oninput="buildLines('  + (lineNum + 1); 
      newEntryLine = newEntryLine + ');"></td><td><input type="text" name="tap-setting-' + (lineNum + 1) + '" id="line-entry-' + ((lineNum + 1) * 6) + '" oninput="buildLines('  + (lineNum + 1); 
      newEntryLine = newEntryLine + ');"></td>';
  
      newrow.innerHTML = newEntryLine;
      newrow.setAttribute("id", "line-" + (lineNum + 1));

      var tbl = document.getElementById('schematic'), // table reference
        i;
      var row = tbl.insertRow(tbl.rows.length);
      row.setAttribute("id", "schematic-line-" + (lineNum + 1))
      row.setAttribute("class", "sch")

      for(i = 0; i < tbl.rows[4].cells.length; i++){
        var cell = row.insertCell(i);
        cell.setAttribute("class", "sch");
        cell.innerHTML = '<img width="150px" src="No-connect.png">'
      }
    }
    document.getElementById(type + "-table").appendChild(newrow);
}
