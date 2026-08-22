# spec-waterfall-skill — Requirements

Intent: a project-agnostic waterfall vibe-coding skill. User imported an external autonomous-QA framework, had it fully sanitized of source-project traces, and repositioned it as a waterfall development method: PM+AI ideation at the top -> formal user-story-only definition in the middle -> implementation and tests BOTH derived from that definition -> tests verify implementation until convergence.

## Core invariants (must not be eroded in future edits)
1. Independent derivation: implementation and tests are two INDEPENDENT branches off the spec.
   - Implementation: derived by agent from spec obligations.
   - Tests: skeletons from `plan_to_tests.py`, filled from spec text ONLY — never from the implementation.
2. Spec is the only asset: derived artifacts (implementation units, test bodies) are consumables — their existence is never a reason to keep them. Guards against the AI patch-forever failure mode (AI prefers modifying existing state over re-deriving, gets stuck in bad local optima).

## Spec authoring rules
- Allium user-story spec: user stories only, no implementation detail (altitude rule).
- Spec must pass the `analyse_spec.py` contradiction gate before derivation starts.

## Verification loop
On failure, the SKILL.md "Rework gate" governs triage (see implementation/INDEX.md). Original design had only return-stage triage; user identified it lacked a rewrite-vs-modify criterion and any anti-sunk-cost enforcement — the gate closes that gap. Loop until all E2E-relevant obligations pass.
