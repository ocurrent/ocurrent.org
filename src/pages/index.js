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
    const { html, frontmatter } = data.markdownRemark;
    const { title, subtitle } = frontmatter;

    return (
      <>
        <div className="wrapper">
          <div className="heading-wrapper">
            <h1 className="title">{title}</h1>
            <h2 className="subtitle">{subtitle}</h2>
          </div>
          <div className="content" dangerouslySetInnerHTML={{ __html: html }} />
        </div>
      </>
    );
  }
}

export const query = graphql`
  query HomePageQuery {
    markdownRemark {
      frontmatter {
        title
        subtitle
      }
      html
    }
  }
`;

export default HomePage;
