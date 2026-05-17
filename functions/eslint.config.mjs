import tseslint from "typescript-eslint";
import importX from "eslint-plugin-import-x";
import {fileURLToPath} from "url";
import path from "path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default tseslint.config(
  {
    ignores: ["lib/**/*", "generated/**/*", "coverage/**/*"],
  },
  {
    files: ["**/*.ts"],
    extends: tseslint.configs.recommended,
    plugins: {
      "import-x": importX,
    },
    languageOptions: {
      parserOptions: {
        project: ["tsconfig.json", "tsconfig.dev.json"],
        tsconfigRootDir: __dirname,
      },
    },
    rules: {
      "quotes": ["error", "double"],
      "indent": ["error", 2],
      "max-len": ["error", {"code": 80, "ignoreComments": true}],
      "import-x/no-unresolved": "off",
    },
  },
  {
    files: ["src/*.test.ts"],
    rules: {
      "max-len": "off",
    },
  },
);
