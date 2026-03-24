{
  programs.lazygit = {
    enable = true;
    settings = {
      customCommands = [
        {
          command = "czg";
          context = "files";
          key = "c";
          output = "terminal";
        }
        {
          command = "czg ai";
          context = "files";
          key = "C";
          output = "terminal";
        }
        {
          key = "<c-f>";
          description = "Search commit messages (all branches)";
          context = "commits";
          prompts = [
            {
              type = "input";
              title = "Search pattern:";
            }
            {
              type = "menuFromCommand";
              title = "Matching commits:";
              command = "git log --all --oneline --grep='{{index .PromptResponses 0}}'";
              filter = "(?P<hash>[a-zA-Z0-9]+) (?P<message>.*)";
              valueFormat = "{{.hash}}";
              labelFormat = "{{.hash | green}} {{.message | yellow}}";
            }
          ];
          command = "git show {{index .PromptResponses 1}}";
          output = "popup";
        }
        {
          key = "<c-g>";
          context = "files";
          output = "terminal";
          loadingText = "Generating commit message with AI...";
          command = ''
            MSG=$(git diff --cached | claude --no-session-persistence --print --model haiku \
              'Generate ONLY a one-line Git commit message following Conventional Commits format \
              (type(scope): description). Types: feat, fix, docs, style, refactor, test, chore. \
              Based strictly on the diff from stdin. Output ONLY the message, nothing else.') \
              && git commit -e -m "$MSG"
          '';
        }
      ];
      gui = {
        language = "ja";
        showIcons = true;
      };
      git = {
        overrideGpg = true;
        branchLogCmd = "git log --graph --color=always --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' {{branchName}} --";
        pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];
        allBranchesLogCmds = [
          "git log --graph --color=always --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all"
        ];
      };
    };
  };
}
