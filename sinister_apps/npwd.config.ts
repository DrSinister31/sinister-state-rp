import App from "./src/App";

export const path = "/sinister_apps";
export default () => ({
  id: "sinister_apps",
  nameLocale: "Sinister Apps",
  color: "#BF5700",
  backgroundColor: "#0d0d14",
  path,
  icon: App,
  app: App,
  notificationIcon: App,
});
