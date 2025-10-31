import { defineConfig } from "jsr:@yuki-yano/zeno@0.2.0";

export default defineConfig(() => {
  // Dynamically fetch snippets from config.yml and add frequently used commands
  const sourceCommand =
    "(grep '^[[:space:]]*- keyword:' ~/.config/zeno/config.yml 2>/dev/null | sed 's/.*keyword:[[:space:]]*//'; printf '%s\\n' git docker npm yarn make kubectl terraform cd ls vim nvim)";

  return {
    snippets: [],
    completions: [
      {
        name: "empty input completion",
        patterns: ["^$"],
        sourceCommand,
        options: {
          "--prompt": "'Select> '",
        },
      },
    ],
  };
});
