import React from "react";

import Header from "./header";

const Layout = ({ children }) => (
  <>
    <Header />

    <>
      <div>{children}</div>
    </>
  </>
);

export default Layout;
