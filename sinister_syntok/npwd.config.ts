import App from "./src/App";
import React from "react";
const ClapIcon = () => React.createElement("svg",{xmlns:"http://www.w3.org/2000/svg",width:24,height:24,viewBox:"0 0 24 24",fill:"none",stroke:"currentColor",strokeWidth:2,strokeLinecap:"round",strokeLinejoin:"round"},[React.createElement("path",{key:"1",d:"M20.2 6 3 11l-.9-2.4c-.3-1.1.3-2.2 1.3-2.5l13.5-4c1.1-.3 2.2.3 2.5 1.3Z"}),React.createElement("path",{key:"2",d:"m6.2 5.3 3.1 3.9"}),React.createElement("path",{key:"3",d:"m12.4 3.4 3.1 4"}),React.createElement("path",{key:"4",d:"M3 11h18v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"})]);
export const path = "/sinister_syntok";
export default () => ({id:"sinister_syntok",nameLocale:"syntok",color:"#ff0050",backgroundColor:"#000",path,icon:ClapIcon,app:App,notificationIcon:ClapIcon});
