const path = require(`path`);

module.exports = {
  siteMetadata: {
    title: "OCurrent",
    description: "",
    author: "@ocamllabs"
  },
  plugins: [
    "gatsby-plugin-react-helmet",
    {
      resolve: `gatsby-source-filesystem`,
      options: {
        name: `data`,
        path: `${__dirname}/data/`
      }
    },
    {
      resolve: `gatsby-transformer-remark`,
      options: {
        classPrefix: "language-",
        inlineCodeMarker: null,
        showLineNumbers: false,
        noInlineHighlight: true
      }
    },
    "gatsby-plugin-sharp",
    "gatsby-transformer-yaml",
    "gatsby-transformer-sharp",
    "gatsby-transformer-inline-svg",
    {
      resolve: `gatsby-plugin-google-fonts`,
      options: {
        fonts: [`Source Code Pro`]
      }
    }
  ]
};
