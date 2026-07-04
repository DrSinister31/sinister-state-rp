import App from "./src/App";
import React from "react";
const SkullIcon = () => React.createElement("svg",{xmlns:"http://www.w3.org/2000/svg",width:24,height:24,viewBox:"0 0 24 24",fill:"none",stroke:"currentColor",strokeWidth:2,strokeLinecap:"round",strokeLinejoin:"round"},[React.createElement("circle",{key:"1",cx:9,cy:12,r:1}),React.createElement("circle",{key:"2",cx:15,cy:12,r:1}),React.createElement("path",{key:"3",d:"M12 2C8 2 5 6 5 10c0 4 3 8 7 10 4-2 7-6 7-10 0-4-3-8-7-8z"}),React.createElement("path",{key:"4",d:"M8 18l-2 3"}),React.createElement("path",{key:"5",d:"M16 18l2 3"})]);
export const path = "/sinister_underworld";
export default () => ({id:"sinister_underworld",nameLocale:"Underworld",color:"#6e2c67",backgroundColor:"#0d0d0d",path,icon:SkullIcon,app:App,notificationIcon:SkullIcon});
