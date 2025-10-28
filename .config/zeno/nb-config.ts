import { defineConfig } from "jsr:@yuki-yano/zeno@0.2.0";

export default defineConfig(async ({ projectRoot, currentDirectory }) => {
  // nb subcommands completion
  const nbSubcommandsCompletion = {
    name: "nb subcommands",
    patterns: [
      "^\\s*nb\\s*$",        // Just "nb"
      "^\\s*nb\\s+help\\s*$", // "nb help"
    ],
    sourceCommand: "nb subcommands",
    options: {
      "--prompt": "'nb subcommand >'",
    },
    callback: "echo {}",  // Just pass through the selected subcommand
  };

  // nb notes completion with smart preview
  const nbNotesCompletion = {
    name: "nb notes",
    patterns: [
      "^nb (e|edit|delete|show|open|peek|copy|move|mv|rename|export|do|pin|unpin|history|browse)( .*)? $",
      "^nb (s|view)( .*)? $",  // Add shortcuts
    ],
    sourceCommand: "nb ls --all --no-color | grep -E '^\\[[0-9]+\\]'",
    options: {
      "--prompt": "'nb >'",
      "--preview": "$ZENO_HOME/nb-preview.sh {}",
      "--preview-window": "'right:60%:wrap'",
    },
    callback: "sed -E 's/^\\[([0-9]+)\\].*/\\1/'",
  };

  // nb add file type completion
  const nbAddTypeCompletion = {
    name: "nb add type",
    patterns: [
      "^nb add --type $",
      "^nb a --type $",
    ],
    sourceCommand: "echo -e 'bookmark\\nfolder\\nimage\\naudio\\nvideo\\ndocument\\ntext\\ntodo'",
    options: {
      "--prompt": "'File type >'",
    },
    callback: "echo {}",
  };

  // nb notebooks completion
  const nbNotebooksCompletion = {
    name: "nb notebooks",
    patterns: [
      "^nb use $",
      "^nb notebooks use $",
      "^nb notebooks delete $",
      "^nb notebooks archive $",
      "^nb notebooks unarchive $",
      "^nb notebooks export $",
    ],
    sourceCommand: "nb notebooks --names --no-color",
    options: {
      "--prompt": "'Notebook >'",
    },
    callback: "echo {}",
  };

  // nb search tag completion
  const nbTagCompletion = {
    name: "nb search tags",
    patterns: [
      "^nb search --tag $",
      "^nb search #",
      "^nb s --tag $",
      "^nb s #",
    ],
    sourceCommand: "nb ls --tags --no-color | tr ',' '\\n' | tr ' ' '\\n' | grep '^#' | sort -u",
    options: {
      "--prompt": "'Tag >'",
    },
    callback: "echo {}",
  };

  // nb import file completion
  const nbImportCompletion = {
    name: "nb import",
    patterns: [
      "^nb import $",
      "^nb i $",
    ],
    sourceCommand: "find . -maxdepth 3 -type f \\( -name '*.md' -o -name '*.txt' -o -name '*.pdf' -o -name '*.html' \\) 2>/dev/null",
    options: {
      "--prompt": "'Import file >'",
      "--preview": "head -20 {}",
    },
    callback: "sed 's|^\\./||'",
  };

  // nb move destination completion
  const nbMoveDestinationCompletion = {
    name: "nb move destination",
    patterns: [
      "^nb (move|mv) [0-9]+ $",
      "^nb (move|mv) .+ $",
    ],
    sourceCommand: "nb notebooks --names --no-color && nb ls --folders --no-color | grep -E '^\\[[0-9]+\\]' | sed -E 's/^\\[([0-9]+)\\].*/\\1/'",
    options: {
      "--prompt": "'Move to >'",
    },
    callback: "echo {}",
  };

  // nb todo operations
  const nbTodoCompletion = {
    name: "nb todo operations",
    patterns: [
      "^nb todo $",
      "^nb todos $",
      "^nb do $",
      "^nb undo $",
    ],
    sourceCommand: "nb ls --type todo --no-color | grep -E '^\\[[0-9]+\\]'",
    options: {
      "--prompt": "'TODO >'",
      "--preview": "$ZENO_HOME/nb-preview.sh {}",
    },
    callback: "sed -E 's/^\\[([0-9]+)\\].*/\\1/'",
  };

  // nb git operations
  const nbGitCompletion = {
    name: "nb git",
    patterns: [
      "^nb git $",
    ],
    sourceCommand: "echo -e 'status\\nlog\\ndiff\\nadd\\ncommit\\npush\\npull\\nfetch\\nbranch\\ncheckout\\nremote'",
    options: {
      "--prompt": "'Git command >'",
    },
    callback: "echo {}",
  };

  // nb export format completion
  const nbExportFormatCompletion = {
    name: "nb export format",
    patterns: [
      "^nb export [0-9]+ $",
      "^nb export .+ $",
    ],
    sourceCommand: "echo -e 'html\\npdf\\ndocx\\nodtx\\nrtf\\nlatex\\nmarkdown\\nplain'",
    options: {
      "--prompt": "'Export format >'",
    },
    callback: "echo {}",
  };

  const completions = [
    nbSubcommandsCompletion,
    nbNotesCompletion,
    nbAddTypeCompletion,
    nbNotebooksCompletion,
    nbTagCompletion,
    nbImportCompletion,
    nbMoveDestinationCompletion,
    nbTodoCompletion,
    nbGitCompletion,
    nbExportFormatCompletion,
  ];

  // nb snippets
  const snippets = [
    {
      name: "nb add bookmark",
      keyword: "nbb",
      snippet: "nb add --type bookmark",
    },
    {
      name: "nb add todo",
      keyword: "nbt",
      snippet: "nb add --type todo --title",
    },
    {
      name: "nb add note",
      keyword: "nba",
      snippet: "nb add",
    },
    {
      name: "nb add folder",
      keyword: "nbf",
      snippet: "nb add --type folder",
    },
    {
      name: "nb search",
      keyword: "nbs",
      snippet: "nb search",
    },
    {
      name: "nb edit",
      keyword: "nbe",
      snippet: "nb edit",
    },
    {
      name: "nb list",
      keyword: "nbl",
      snippet: "nb ls --limit 20",
    },
    {
      name: "nb list all",
      keyword: "nbla",
      snippet: "nb ls --all",
    },
    {
      name: "nb list todos",
      keyword: "nblt",
      snippet: "nb ls --type todo",
    },
    {
      name: "nb list bookmarks",
      keyword: "nblb",
      snippet: "nb ls --type bookmark",
    },
    {
      name: "nb git status",
      keyword: "nbg",
      snippet: "nb git status",
    },
    {
      name: "nb git commit",
      keyword: "nbgc",
      snippet: "nb git add . && nb git commit -m",
    },
    {
      name: "nb sync",
      keyword: "nbsync",
      snippet: "nb sync",
    },
    {
      name: "nb browse",
      keyword: "nbbr",
      snippet: "nb browse",
    },
    {
      name: "nb notebooks list",
      keyword: "nbn",
      snippet: "nb notebooks",
    },
    {
      name: "nb use notebook",
      keyword: "nbu",
      snippet: "nb use",
    },
    {
      name: "nb export html",
      keyword: "nbeh",
      snippet: "nb export --format html",
    },
    {
      name: "nb export pdf",
      keyword: "nbep",
      snippet: "nb export --format pdf",
    },
  ];

  return {
    snippets,
    completions,
  };
});