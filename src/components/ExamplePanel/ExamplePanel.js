import React from "react";

import "./ExamplePanel.css";

const ExamplePanel = ({ frontmatter, html, excerpt }) => {
  const { path, title } = frontmatter;

  return (
    <div className="link">
      <div>{title}</div>
      <div>{path}</div>
      <div dangerouslySetInnerHTML={{ __html: html }} />
    </div>
  );
};

export default ExamplePanel;
