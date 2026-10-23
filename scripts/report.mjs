#!/usr/bin/env node
// Turns loams-listing's verify report and lint log into the pull request's report (Markdown).
// OUTCOMES holds each step's outcome (`setup=success lint=failure …`): a step that did not
// succeed is reported as failed or not run, never read as a pass from missing output.
//
//   OUTCOMES='…' node scripts/report.mjs <verify-report.json> <lint.log> > report.md
import { existsSync, readFileSync } from 'node:fs';

const [reportFile, lintFile] = process.argv.slice(2);
const outcomes = Object.fromEntries(
  (process.env.OUTCOMES ?? '')
    .split(/\s+/)
    .filter(Boolean)
    .map((pair) => pair.split('=')),
);
const STEPS = [
  ['setup', 'loams-listing built'],
  ['changed', 'only new versions added'],
  ['lint', 'lint (first-party only)'],
  ['build', 'the index builds'],
  ['verify', 'artifacts, integrity and provenance'],
];
const label = (outcome) =>
  outcome === 'success' ? 'ok' : outcome === 'skipped' || outcome === '' || outcome === undefined ? '**not run**' : `**${outcome}**`;
const allPassed = STEPS.every(([id]) => outcomes[id] === 'success');

const lines = ['<!-- loams-marketplace-report -->', `## Seed Exchange: listing check ${allPassed ? 'passed' : 'did not pass'}`, ''];
lines.push('| Step | Result |', '|---|---|');
for (const [id, name] of STEPS) lines.push(`| ${name} | ${label(outcomes[id])} |`);
lines.push('');

const reports = reportFile && existsSync(reportFile) ? JSON.parse(readFileSync(reportFile, 'utf8')) : null;
if (reports === null) {
  lines.push(outcomes.verify === 'success' ? 'No listing versions added.' : 'Verification did not produce a report.', '');
} else if (reports.length === 0) {
  lines.push('No listing versions added in this pull request.', '');
}
for (const report of reports ?? []) {
  lines.push(`### ${report.ok ? 'Passed' : 'Failed'}: \`${report.id}@${report.version}\``, '');
  lines.push('| Check | Result | Detail |', '|---|---|---|');
  for (const check of report.checks) {
    const detail = String(check.detail).replaceAll('|', '\\|');
    lines.push(`| ${check.check} | ${check.ok ? 'ok' : '**failed**'} | ${detail} |`);
  }
  lines.push('');
}
const lint = lintFile && existsSync(lintFile) ? readFileSync(lintFile, 'utf8').trim() : '';
if (lint) lines.push('### Lint output', '', `\`\`\`\n${lint}\n\`\`\``, '');
lines.push('LAPC Core conformance is not part of this check yet: its runner is MK1 Task 8.');
process.stdout.write(`${lines.join('\n')}\n`);
