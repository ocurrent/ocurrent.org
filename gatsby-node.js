const path = require(`path`);

exports.createPages = ({ actions, graphql }) => {
  const { createPage } = actions;

  const exampleTemplate = path.resolve(`src/templates/example.js`);

  return graphql(`
    query {
      allMarkdownRemark(
        sort: { order: ASC, fields: [frontmatter___path] }
        filter: { fileAbsolutePath: { regex: "/data/examples/.*.md$/" } }
      ) {
        edges {
          node {
            frontmatter {
              path
            }
          }
        }
      }
    }
  `).then(result => {
    if (result.errors) {
      return Promise.reject(result.errors);
    }

    return result.data.allMarkdownRemark.edges.forEach(({ node }) => {
      createPage({
        path: node.frontmatter.path,
        component: exampleTemplate,
        context: {}
      });
    });
  });
};
