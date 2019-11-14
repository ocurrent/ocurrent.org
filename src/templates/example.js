import React from "react";
import Prism from "prismjs";
import "prismjs/components/prism-ocaml";
import { graphql } from "gatsby";

import Header from "../components/header";

class Template extends React.Component {
  componentDidMount() {
    Prism.highlightAll();
  }

  render() {
    const { data } = this.props;
    const { markdownRemark } = data;
    const { frontmatter, html } = markdownRemark;
    const { title } = frontmatter;

    return (
      <>
        <Header />
        <div className="wrapper">
          <br />
          <h1>{title}</h1>
          <div className="content" dangerouslySetInnerHTML={{ __html: html }} />
        </div>
      </>
    );
  }
}

export const pageQuery = graphql`
  query($path: String!) {
    markdownRemark(frontmatter: { path: { eq: $path } }) {
      html
      frontmatter {
        title
      }
    }
  }
`;

export default Template;
