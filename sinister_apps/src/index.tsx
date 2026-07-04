import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

var root = document.getElementById("root");
if (root) {
  ReactDOM.createRoot(root).render(React.createElement(App));
}
