import { Tooltip } from "bootstrap"

const tooltip = new Tooltip(document.getElementById("tooltip-button"))
tooltip.show() // positioned via the bundled @floating-ui/dom
document.body.dataset.bootstrap = "loaded"
