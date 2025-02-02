function changeBusType(sourceValue, idValue) {
  const busTypeImages = {
    slack: "Slack.png",
    generator: "Generator.png",
    default: "Load.png"
  };

  const sourceElement = document.getElementById(sourceValue);
  const targetElement = document.getElementById(idValue);

  if (!sourceElement || !targetElement) return;

  const selectedType = sourceElement.value;
  const imageSrc = busTypeImages[selectedType] || busTypeImages.default;

  targetElement.innerHTML = `<img width="150px" src="${imageSrc}">`;
}
