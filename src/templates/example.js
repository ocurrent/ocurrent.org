import React from "react";
import Prism from "prismjs";
import "prismjs/components/prism-ocaml";
import { graphql } from "gatsby";

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
        <div className="wrapper">
          <div className="heading-wrapper">
            <h1 class="title-large">Tutorials</h1>
          </div>
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
