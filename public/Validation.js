var flag = [];

function Validation(type, volt, ang, pgi, qgi, pli, qli, qmin, qmax, lineNum){
		
	var busTypes = document.getElementById(type).value;
	var busVoltages = document.getElementById(volt).value;
	var busAngles = document.getElementById(ang).value;
	var busPValues = document.getElementById(pgi).value;
	var busQValues = document.getElementById(qgi).value;
	var busPLiValues = document.getElementById(pli).value;
	var busQLiValues = document.getElementById(qli).value;
	var busQmin = document.getElementById(qmin).value;
	var busQmax = document.getElementById(qmax).valie;

	

	var voltageCheck = busVoltages.search(" ");
	var angleCheck = busAngles.search(" ");
	var pvalueCheck = busPValues.search(" ");
	var qvalueCheck = busQValues.search(" ");
	console.log(busTypes + ' ' + busVoltages + ' ' + busAngles + ' ' + busPValues + ' ' + busQValues +'test');

	document.getElementById('line-'+lineNum).innerHTML = '<img width="20px" src="checkmark.png">';
	document.getElementById('submitButton').disabled = false;

	var i;
	for(i=0; i < flag.length; i++){
		if (flag[i] === lineNum){
			flag.splice(i,1);
		}
	}

	if(busTypes == "slack"){
	console.log("Slack");
	console.log(busVoltages);
			if(isNaN(busVoltages) || isNaN(busAngles) || busVoltages == "" || busAngles == "" || voltageCheck > 0 || angleCheck > 0){
				document.getElementById('line-'+lineNum).innerHTML = '<img width="20px" src="redx.png">';
				document.getElementById('submitButton').disabled = true;
				console.log("slack not valid");
				flag.push(lineNum);
			}
		}else if(busTypes == "generator"){
		console.log("Generator");
			if(isNaN(busPValues) || isNaN(busVoltages || busPValues == "" || busVoltages == "" || pvalueCheck > 0 || voltageCheck > 0 || isNaN(busPLiValues))){
				document.getElementById('line-'+lineNum).innerHTML = '<img width="20px" src="redx.png">';
				document.getElementById('submitButton').disabled = true;
				console.log("generator not valid");
				flag.push(lineNum);
			}
		}else if(busTypes == "load"){
		console.log("Load");
			if(isNaN(busPValues) || isNaN(busQValues || busPValues == "" || busQValues == "" || pvalueCheck > 0 || qvalueCheck > 0 || isNaN(busPLiValues) || isNaN(busQLiValues) || isNaN(busQmax) || isNaN(busQmin))){
				document.getElementById('line-'+lineNum).innerHTML = '<img width="20px" src="redx.png">';
				document.getElementById('submitButton').disabled = true;
				console.log("load not valid");
				flag.push(lineNum);
			}
		}
	console.log(flag.length);
}