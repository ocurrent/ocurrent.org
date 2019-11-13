import React from "react";
import { graphql } from "gatsby";

import "./index.css";

const HomePage = ({ data }) => {
  const { html } = data.markdownRemark;

  return (
          <>
          <div className="wrapper">
          <h1 className="title">OCurrent</h1>
          <div dangerouslySetInnerHTML={{ __html: html }} />
          </div>
    </>
  );
};

export const query = graphql`
  query HomePageQuery {
    markdownRemark {
      html
    }
  }
`;

export default HomePage;
