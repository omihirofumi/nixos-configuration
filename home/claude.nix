{ config, USERNAME, ... }:
let
  # ghq default root layout
  repoRoot = "/Users/${USERNAME}/ghq/hobby/github.com/omihirofumi/nixos-configuration/home/claude";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${path}";
in
{
  home.file.".claude/CLAUDE.md".source = mkLink "CLAUDE.md";
  home.file.".claude/rules/interaction.md".source = mkLink "rules/interaction.md";
  home.file.".claude/skills/deep-codebase-research/SKILL.md".source = mkLink "skills/deep-codebase-research/SKILL.md";
  home.file.".claude/skills/output-plan-detailed/SKILL.md".source = mkLink "skills/output-plan-detailed/SKILL.md";
}
