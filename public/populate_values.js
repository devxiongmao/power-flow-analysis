function populateValues(sourceValue, idValue) {
  const numMatch = sourceValue.match(/\d+/);
  if (!numMatch) return;

  const num = parseInt(numMatch[0], 10);
  const x = document.getElementById(sourceValue)?.value;
  if (x === undefined) return;

  const labels = ["QMax", "V", "A", "PGi", "QGi", "PLi", "QLi", "QMin"];
  document.getElementById(idValue).innerHTML = `${labels[num % 8]}:  ${x}`;
}