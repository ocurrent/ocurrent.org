import React from "react";
import { graphql } from "gatsby";
import Img from "gatsby-image";
import Helmet from "react-helmet";

import Layout from "../components/layout";

import "./blog.css";

const BlogPanel = ({ post }) => {
  const { author, author_profile, date, excerpt, link, title, image } = post;

  return (
    <div className="blog-panel">
      <div className="blog-panel-image">
        <Img className="imgBg" fluid={image.childImageSharp.fluid} />
      </div>
      <div className="blog-panel-body">
        <h2 className="blog-panel-title">
          <a href={link} target="_blank" rel="noopener noreferrer">
            {title}
          </a>
        </h2>
        <span className="blog-panel-subtitle">
          by{" "}
          <a href={author_profile} target="_blank" rel="noopener noreferrer">
            {author}
          </a>{" "}
          on {date}
        </span>
        <div className="blog-panel-excerpt">{excerpt}</div>
        <div className="blog-panel-more">
          <a href={link} target="_blank" rel="noopener noreferrer">
            Read more →
          </a>
        </div>
      </div>
    </div>
  );
};

export default function Template({ data }) {
  const posts = data.allBlogYaml.edges.map(({ node }) => node);
  return (
    <Layout>
      <Helmet title="Blog | OCurrent" />
      <div className="wrapper">
        <h1 className="title">Blog</h1>
        {posts.map(post => (
          <BlogPanel post={post} />
        ))}
      </div>
    </Layout>
  );
}

export const pageQuery = graphql`
  query {
    allBlogYaml {
      edges {
        node {
          title
          author
          author_profile
          date(formatString: "MMM Do, YYYY")
          excerpt
          link
          image {
            childImageSharp {
              fluid(cropFocus: ATTENTION, maxWidth: 360, maxHeight: 420) {
                ...GatsbyImageSharpFluid_noBase64
              }
            }
          }
        }
      }
    }
  }
`;
