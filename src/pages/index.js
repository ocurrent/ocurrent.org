import React from "react";
import Prism from "prismjs";
import "prismjs/components/prism-ocaml";
import { graphql } from "gatsby";

import "./index.css";

class HomePage extends React.Component {
  componentDidMount() {
    Prism.highlightAll();
  }

  render() {
    const { data } = this.props;
    const { html } = data.markdownRemark;

    return (
      <>
        <div className="wrapper">
          <h1 className="title">OCurrent</h1>
          <div dangerouslySetInnerHTML={{ __html: html }} />
        </div>
      </>
    );
  }
}

export const query = graphql`
  query HomePageQuery {
    markdownRemark {
      html
    }
  }
`;

export default HomePage;
