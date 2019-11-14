import React from "react";

import "./header.css";

const Header = () => (
  <header className="navbar">
    <div className="wrapper">
      <ul className="navbar-nav flex-row">
        <li className="nav-item">
          <a className="nav-link" href="/">
            Home
          </a>
        </li>
        <li className="nav-item">
          <a className="nav-link" href="/tutorial/01">
            Tutorials
          </a>
        </li>
      </ul>
    </div>
  </header>
);

export default Header;
