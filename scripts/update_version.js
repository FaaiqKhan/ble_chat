const fs = require('fs');

const version = process.argv[2];
if (!version) {
  console.error('Usage: node scripts/update_version.js <semver>');
  process.exit(1);
}

const pubspecPath = './pubspec.yaml';
const content = fs.readFileSync(pubspecPath, 'utf8');

const match = content.match(/^version:\s+\d+\.\d+\.\d+\+(\d+)/m);
if (!match) {
  console.error('Could not find version line in pubspec.yaml');
  process.exit(1);
}

const nextBuild = parseInt(match[1], 10) + 1;
const updated = content.replace(
  /^version:\s+\d+\.\d+\.\d+\+\d+/m,
  `version: ${version}+${nextBuild}`,
);

fs.writeFileSync(pubspecPath, updated);
console.log(`pubspec.yaml updated to ${version}+${nextBuild}`);

const changelogPath = './CHANGELOG.md';
const changelog = fs.readFileSync(changelogPath, 'utf8');
if (changelog.includes('## [Unreleased]')) {
  fs.writeFileSync(changelogPath, changelog.replace('## [Unreleased]', `## [${version}]`));
  console.log(`CHANGELOG.md [Unreleased] → [${version}]`);
} else {
  console.warn('CHANGELOG.md has no [Unreleased] section — skipping.');
}