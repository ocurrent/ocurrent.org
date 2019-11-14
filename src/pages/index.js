import React from "react";
import { graphql } from "gatsby";
import Helmet from "react-helmet";

import Prism from "prismjs";
import "prismjs/components/prism-ocaml";

import Layout from "../components/layout";
import Footer from "../components/footer";

import "./index.css";

class HomePage extends React.Component {
  componentDidMount() {
    Prism.highlightAll();
  }

  render() {
    const { data } = this.props;
    const { ocamllabs, tarides, allMarkdownRemark } = data;
    const { html, frontmatter } = allMarkdownRemark.edges[0].node;
    const { title, subtitle } = frontmatter;

    return (
      <Layout>
        <Helmet title="OCurrent" />
        <div className="wrapper">
          <div className="heading-wrapper">
            <h1 className="title-large">{title}</h1>
            <h2 className="subtitle">{subtitle}</h2>
          </div>
          <div className="content" dangerouslySetInnerHTML={{ __html: html }} />
          <Footer logos={{ ocamllabs: ocamllabs, tarides: tarides }} />
        </div>
      </Layout>
    );
  }
}

export const query = graphql`
  query HomePageQuery {
    ocamllabs: file(
      sourceInstanceName: { eq: "data" }
      relativePath: { eq: "logos/ocamllabs.png" }
    ) {
      childImageSharp {
        fixed(height: 70) {
          ...GatsbyImageSharpFixed
        }
      }
    }
    tarides: file(
      sourceInstanceName: { eq: "data" }
      relativePath: { eq: "logos/tarides.png" }
    ) {
      childImageSharp {
        fixed(height: 70) {
          ...GatsbyImageSharpFixed
        }
      }
    }
    allMarkdownRemark(
      filter: { fileAbsolutePath: { regex: "/data/index.md$/" } }
    ) {
      edges {
        node {
          frontmatter {
            title
            subtitle
          }
          html
        }
      }
    }
  }
`;

export default HomePage;
