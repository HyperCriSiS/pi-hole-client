import docusaurusPlugin from "@docusaurus/eslint-plugin";
import tsParser from "@typescript-eslint/parser";

export default [
  {
    files: ["**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaFeatures: {jsx: true},
        sourceType: "module",
      },
    },
    plugins: {
      "@docusaurus": docusaurusPlugin,
    },
    rules: docusaurusPlugin.configs.recommended.rules,
  },
];
