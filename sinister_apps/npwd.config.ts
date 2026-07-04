import App from "./src/App";
import React from "react";

const BuildingIcon = () => React.createElement("svg", {
  xmlns: "http://www.w3.org/2000/svg", width: 24, height: 24, viewBox: "0 0 24 24",
  fill: "none", stroke: "currentColor", strokeWidth: 2, strokeLinecap: "round", strokeLinejoin: "round"
}, [
  React.createElement("rect", { key: 1, x: 4, y: 2, width: 16, height: 20, rx: 2, ry: 2 }),
  React.createElement("path", { key: 2, d: "M9 22v-4h6v4" }),
  React.createElement("path", { key: 3, d: "M8 6h.01" }),
  React.createElement("path", { key: 4, d: "M16 6h.01" }),
  React.createElement("path", { key: 5, d: "M12 6h.01" }),
  React.createElement("path", { key: 6, d: "M12 10h.01" }),
  React.createElement("path", { key: 7, d: "M12 14h.01" }),
  React.createElement("path", { key: 8, d: "M16 10h.01" }),
  React.createElement("path", { key: 9, d: "M16 14h.01" }),
  React.createElement("path", { key: 10, d: "M8 10h.01" }),
  React.createElement("path", { key: 11, d: "M8 14h.01" }),
]);

export const path = "/sinister_apps";
export default () => ({
  id: "sinister_apps",
  nameLocale: "Sinister",
  color: "#BF5700",
  backgroundColor: "#0d0d14",
  path,
  icon: BuildingIcon,
  app: App,
  notificationIcon: BuildingIcon,
});
