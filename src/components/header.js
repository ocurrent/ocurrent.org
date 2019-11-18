import React from "react";
import { Link, StaticQuery, graphql } from "gatsby";

import "./header.css";

const Header = () => {
  return (
    <StaticQuery
      query={graphql`
        query {
          file(
            relativePath: { eq: "logos/github.svg" }
            sourceInstanceName: { eq: "data" }
          ) {
            publicURL
          }
        }
      `}
      render={data => {
        const githubUrl = data.file.publicURL;
        return (
          <header className="navbar">
            <div className="wrapper">
              <ul className="navbar-nav flex-row">
                <li className="nav-item">
                  <Link
                    className="nav-link"
                    activeClassName="nav-link-active"
                    to="/"
                  >
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
                <li className="nav-item">
                  <Link
                    className="nav-link"
                    activeClassName="nav-link-active"
                    partiallyActive={true}
                    to="/blog"
                  >
                    Blog
                  </Link>
                </li>
              </ul>
              <ul className="navbar-nav navbar-nav-right flex-row">
                <a href="https://github.com/ocurrent/ocurrent">
                  <img className="icon-github" src={githubUrl} alt="" />
                </a>
              </ul>
            </div>
          </header>
        );
      }}
    />
  );
};

export default Header;
