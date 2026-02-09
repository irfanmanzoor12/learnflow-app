/** @type {import('@docusaurus/types').Config} */
const config = {
  title: "LearnFlow",
  tagline: "AI-Powered Python Tutoring Platform",
  url: "https://learnflow.dev",
  baseUrl: "/",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",
  favicon: "img/favicon.ico",
  organizationName: "irfanmanzoor12",
  projectName: "learnflow-app",

  presets: [
    [
      "classic",
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: { sidebarPath: require.resolve("./sidebars.js"), routeBasePath: "/" },
        blog: false,
        theme: { customCss: require.resolve("./src/css/custom.css") },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: "LearnFlow",
        items: [
          { type: "docSidebar", sidebarId: "docs", position: "left", label: "Docs" },
          { href: "https://github.com/irfanmanzoor12/learnflow-app", label: "GitHub", position: "right" },
        ],
      },
      footer: {
        style: "dark",
        copyright: `Built with Skills + MCP Code Execution pattern. Hackathon III.`,
      },
    }),
};

module.exports = config;
