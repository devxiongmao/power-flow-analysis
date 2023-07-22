function changeBusType(sourceValue, idValue){
  var x = document.getElementById(sourceValue).value;
  if (x == "slack") {
  	document.getElementById(idValue).innerHTML = '<img width="150px" src="Slack.png">';
  } else if (x == "generator") {
  	document.getElementById(idValue).innerHTML = '<img width="150px" src="Generator.png">';
  } else {
  	document.getElementById(idValue).innerHTML = '<img width="150px" src="Load.png">';
  }
}