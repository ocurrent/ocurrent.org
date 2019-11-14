import React from "react";
import { Link } from "gatsby";

import "./header.css";

const Header = () => (
  <header className="navbar">
    <div className="wrapper">
      <ul className="navbar-nav flex-row">
        <li className="nav-item">
          <Link className="nav-link" activeClassName="nav-link-active" to="/">
            Home
          </Link>
        </li>
        <li className="nav-item">
          <Link
            className="nav-link"
            activeClassName="nav-link-active"
            partiallyActive={true}
            to="/examples"
          >
            Examples
          </Link>
        </li>
      </ul>
    </div>
  </header>
);

export default Header;
