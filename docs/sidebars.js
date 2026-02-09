/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docs: [
    "intro",
    "architecture",
    {
      type: "category",
      label: "Services",
      items: ["services/triage-agent", "services/concepts-agent", "services/code-runner"],
    },
    {
      type: "category",
      label: "Skills",
      items: ["skills/overview", "skills/mcp-pattern"],
    },
    "deployment",
    "api-reference",
  ],
};

module.exports = sidebars;
