// commitlint config — enforced by the commit-msg hook and referenced by CI.
// Conventional Commits: <type>(<scope>): <subject>
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Keep subjects scannable in `git log --oneline`
    'header-max-length': [2, 'always', 72],
    // Types allowed in this stack (the conventional set, no custom additions)
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert'],
    ],
  },
};
