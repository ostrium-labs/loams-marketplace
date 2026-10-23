#!/usr/bin/env node
// Turns loams-listing's verify report and lint log into the pull request's report (Markdown).
//
//   node scripts/report.mjs <verify-report.json> <lint.log> > report.md
import { existsSync, readFileSync } from 'node:fs';

const [reportFile, lintFile] = process.argv.slice(2);
const reports = reportFile && existsSync(reportFile) ? JSON.parse(readFileSync(reportFile, 'utf8')) : [];
const lint = lintFile && existsSync(lintFile) ? readFileSync(lintFile, 'utf8').trim() : '';
const lines = ['<!-- loams-marketplace-report -->', '## Seed Exchange: listing check', ''];
if (reports.length === 0) lines.push('No listing versions added in this pull request.', '');
for (const report of reports) {
  lines.push(`### ${report.ok ? 'Passed' : 'Failed'}: \`${report.id}@${report.version}\``, '');
  lines.push('| Check | Result | Detail |', '|---|---|---|');
  for (const check of report.checks) {
    const detail = String(check.detail).replaceAll('|', '\\|');
    lines.push(`| ${check.check} | ${check.ok ? 'ok' : '**failed**'} | ${detail} |`);
  }
  lines.push('');
}
lines.push('### Lint', '', lint ? `\`\`\`\n${lint}\n\`\`\`` : 'Every listing passes `loams-listing lint --first-party-only`.', '');
lines.push('LAPC Core conformance is not part of this check yet: its runner is MK1 Task 8.');
process.stdout.write(`${lines.join('\n')}\n`);
