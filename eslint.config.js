/**
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
 */

const js = require("@eslint/js");

module.exports = [
  {
    ignores: ["target/**/*"]
  },
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "script",
      globals: {
        $: "readonly",
        Chart: "readonly",
        alert: "readonly",
        console: "readonly",
        document: "readonly",
        navigator: "readonly",
        setInterval: "readonly",
        window: "readonly"
      }
    },
    rules: {
      semi: "error",
      "prefer-const": "error"
    }
  }
];
