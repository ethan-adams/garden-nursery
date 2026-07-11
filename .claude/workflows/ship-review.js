export const meta = {
  name: 'ship-review',
  description: 'Multi-agent review gate for /ship: parallel skeptics per dimension, every finding adversarially verified before it can block',
  whenToUse: 'Called by the /ship skill after implementation and before verification/publish. args: { base: "origin/main" }. The gate passes only when gatePassed is true.',
  phases: [
    { title: 'Find', detail: 'one skeptic per review dimension' },
    { title: 'Verify', detail: 'two refuters per finding; unanimous survival required' },
  ],
}

const base = (args && args.base) || 'origin/main'

// Self-contained persona so the gate does not depend on the session's agent registry
// (custom agent types added mid-session or absent in headless runs would silently break it).
const SKEPTIC =
  'You are a read-only adversarial reviewer for the garden-nursery repo, a Steam Deck-first ' +
  'Godot 4.5 cozy nursery sim. Never edit files; use read-only git commands and file reads. ' +
  'Assume the author is a rival studio that did a kind of bad job; demand evidence from the ' +
  'code in front of you. Style preferences and hypotheticals that depend on code not in this ' +
  'repo do not count. An empty result is a valid result. ' +
  'Repo-specific lenses: design-fit = Steam Deck constraints (controller-first, readable at ' +
  '1280x800, no hover-only or pointer-only core actions — docs/steam-deck-ux-baseline.md), ' +
  'creative direction (writing must be warm/specific/observant, never generic cozy filler — ' +
  'docs/creative-direction.md), and the yard-first rule (the walkable nursery yard stays the ' +
  'first screen; no dashboard-first regressions); ' +
  'correctness = state, save/load, signal-wiring, and boundary errors a player would hit, ' +
  'including GDScript/scene mismatches (missing nodes, renamed exports, broken NodePaths) and ' +
  'drift between godot/scripts/core rules and the scripts/simulation-rules.mjs mirror; ' +
  'scope = unrelated changes, stray files, complexity an existing utility already covers; ' +
  'tests = changed rules or data shapes with no covering check in npm test (simulation-rules ' +
  'tests, validate-data, agent-check), or tests asserting implementation not behavior. '

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'line', 'severity', 'summary', 'failure_scenario'],
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['blocker', 'minor'] },
          summary: { type: 'string' },
          failure_scenario: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['refuted', 'reason'],
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string' },
  },
}

const DIMENSIONS = ['correctness', 'design-fit', 'scope', 'tests']
const failedDimensions = []

const results = await pipeline(
  DIMENSIONS,
  dimension =>
    agent(
      SKEPTIC +
        `Your dimension: ${dimension}. Review the working diff against base ${base} ` +
        `(git diff ${base}...HEAD, plus staged and untracked files — git status --porcelain). ` +
        `Report each defect with its exact file and line and a concrete failure scenario. Severity ` +
        `"blocker" = would ship a real bug, a broken check, or a clear product-guardrail violation; ` +
        `otherwise "minor".`,
      { label: `find:${dimension}`, phase: 'Find', schema: FINDINGS_SCHEMA },
    ),
  (review, dimension) => {
    if (!review) {
      failedDimensions.push(dimension)
      return []
    }
    return parallel(
      review.findings.map(finding => () =>
        parallel(
          [1, 2].map(i => () =>
            agent(
              SKEPTIC +
                `A ${dimension} reviewer of the diff vs ${base} reported this finding: ` +
                `${finding.file}:${finding.line} — ${finding.summary}. ` +
                `Claimed failure scenario: ${finding.failure_scenario}. ` +
                `Refuter #${i}: your job is to kill this finding. Re-read the actual code, check whether ` +
                `the claimed failure can really occur, and look for guards, callers, or tests that make it ` +
                `impossible. Default to refuted=true when the evidence is ambiguous.`,
              { label: `refute:${finding.file}:${finding.line}`, phase: 'Verify', schema: VERDICT_SCHEMA },
            ),
          ),
        ).then(verdicts => {
          const votes = verdicts.filter(Boolean)
          // Fail closed like the Find phase: if every refuter errored, the finding is
          // unverified and must survive rather than be silently discarded.
          const survives = votes.length === 0 || votes.every(v => !v.refuted)
          const reasons = votes.length === 0 ? ['unverified: all refuters errored; kept conservatively'] : votes.map(v => v.reason)
          return { ...finding, dimension, survives, unverified: votes.length === 0, verdicts: reasons }
        }),
      ),
    )
  },
)

const confirmed = results.filter(Boolean).flat().filter(Boolean).filter(f => f.survives)
const blockers = confirmed.filter(f => f.severity === 'blocker')
const minors = confirmed.filter(f => f.severity === 'minor')
const gatePassed = blockers.length === 0 && failedDimensions.length === 0

log(
  `${blockers.length} blocker(s), ${minors.length} minor finding(s) survived adversarial verification` +
    (failedDimensions.length ? `; FAILED dimensions (gate does not pass): ${failedDimensions.join(', ')}` : ''),
)

return { gatePassed, blockers, minors, failedDimensions }
