import React from "react";
import { Link } from "gatsby";

import "./ExamplePanel.css";

const ExamplePanel = ({ frontmatter, html, excerpt, index }) => {
  const { path, title, image } = frontmatter;
  console.log(frontmatter);

  return (
    <div className="link">
      <Link to={path}>
        <div className="image-pane">
          <img className="image-bg" src={image.publicURL} alt="" />
        </div>
      </Link>
      <div className="title-pane">
        <h3 className="title">
          <Link to={path}>
            <span class="index">{index}.</span> {title}
          </Link>
        </h3>
        <div dangerouslySetInnerHTML={{ __html: excerpt }} />
      </div>
    </div>
  );
};

export default ExamplePanel;
