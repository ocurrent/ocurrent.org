import React from "react";
import { graphql } from "gatsby";
import Helmet from "react-helmet";

import Layout from "../components/layout";
import ExamplePanel from "../components/ExamplePanel/ExamplePanel";

export default function Template({ data }) {
  const examples = data.allMarkdownRemark.edges;

  return (
    <Layout>
      <Helmet title="Examples | OCurrent" />
      <div className="wrapper">
        <br />
        {examples.map(({ node }) => {
          const path = node.frontmatter.path;
          const index = parseInt(path.slice(-2));

          return (
            <ExamplePanel
              index={index}
              frontmatter={node.frontmatter}
              html={node.html}
              excerpt={node.excerpt}
            />
          );
        })}
      </div>
    </Layout>
  );
}

export const pageQuery = graphql`
  query {
    allMarkdownRemark(
      sort: { order: ASC, fields: [frontmatter___path] }
      filter: { fileAbsolutePath: { regex: "/data/examples/.*.md$/" } }
    ) {
      edges {
        node {
          excerpt
          frontmatter {
            title
            subtitle
            path
            image {
              publicURL
            }
          }
        }
      }
    }
  }
`;
