function populateValues(sourceValue, idValue){
  var num = sourceValue.match(/\d+/);
  var x = document.getElementById(sourceValue).value;

  num = parseInt(num, 10);

  if (num % 8 == 0){
    document.getElementById(idValue).innerHTML = "QMax:  " + x;
  }else if(num % 8 == 1){
    document.getElementById(idValue).innerHTML = "V:  " + x;
  }else if(num % 8 == 2){
    document.getElementById(idValue).innerHTML = "A:  " + x;
  }else if(num % 8 == 3){
    document.getElementById(idValue).innerHTML = "PGi:  " + x;
  }else if(num % 8 == 4){
    document.getElementById(idValue).innerHTML = "QGi:  " + x;
  }else if(num % 8 == 5){
    document.getElementById(idValue).innerHTML = "PLi:  " + x;
  }else if(num % 8 == 6){
    document.getElementById(idValue).innerHTML = "QLi:  " + x;
  }else if(num % 8 == 7){
    document.getElementById(idValue).innerHTML = "QMin:  " + x;
  }
}