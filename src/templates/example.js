import React from "react";
import { graphql } from "gatsby";
import Helmet from "react-helmet";

import Prism from "prismjs";
import "prismjs/components/prism-ocaml";

import Layout from "../components/layout";

class Template extends React.Component {
  componentDidMount() {
    Prism.highlightAll();
  }

  render() {
    const { data } = this.props;
    const { markdownRemark } = data;
    const { frontmatter, html } = markdownRemark;
    const { title, path } = frontmatter;

    const index = parseInt(path.slice(-2));

    return (
      <Layout>
        <Helmet title={`Example ${index} | OCurrent`} />
        <div className="wrapper">
          <br />
          <h1>{title}</h1>
          <div className="content" dangerouslySetInnerHTML={{ __html: html }} />
        </div>
      </Layout>
    );
  }
}

export const pageQuery = graphql`
  query($path: String!) {
    markdownRemark(frontmatter: { path: { eq: $path } }) {
      html
      frontmatter {
        title
        path
      }
    }
  }
`;

export default Template;
