import React from "react";
import Img from "gatsby-image";

import "./footer.css";

const CompanyBadge = ({ image, href, alt, verticalAlign }) => {
  return (
    <a href={href} target="_blank" rel="noopener noreferrer">
      <Img
        fixed={image.childImageSharp.fixed}
        alt={alt}
        style={{ "vertical-align": "text-bottom" }}
      />
    </a>
  );
};

const Footer = ({ logos }) => {
  return (
    <>
      <hr class="footer-div" />
      <footer class="footer">
        <div className="badge-row">
          <div className="badge">
            <CompanyBadge
              alt="OCaml Labs"
              href="http://ocamllabs.io/"
              image={logos.ocamllabs}
            />
          </div>
          <div className="badge">
            <CompanyBadge
              alt="Tarides"
              href="https://tarides.com/"
              image={logos.tarides}
            />
          </div>
        </div>
        <p>
          OCurrent is developed and maintained by OCaml Labs and Tarides for use
          in the OCaml open-source community.
        </p>

        <p>
          © 2019, the OCurrent authors. Distributed under the{" "}
          <a href="https://github.com/ocurrent/ocurrent/blob/master/LICENSE">
            Apache-2.0 license
          </a>
          .
        </p>
      </footer>
    </>
  );
};

export default Footer;
