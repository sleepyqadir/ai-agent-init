---
name: tdd
description: |
  Use when implementing features or fixing bugs with test-driven development.
  Triggers: "TDD", "test first", "write tests first", "red green refactor", "test-driven".
  The failing test must exist before production code. No exceptions.
---

# Test-Driven Development

**The rule:** No production code exists without a failing test that demanded it.

## RED — Write a Failing Test

1. Write the simplest test that describes one specific behavior
2. Name it: `should [expected outcome] when [condition]`
3. Run it. It MUST fail. If it passes, either the test is wrong or the feature already exists.
4. Test only one behavior per test.

## GREEN — Make It Pass

1. Write the minimum code to make the test pass
2. Do not write code "for later" or "just in case"
3. Hardcoding is acceptable if that's the minimum — generalize in REFACTOR
4. Run the test. It MUST pass now.

## REFACTOR — Clean Up

1. Remove duplication between test and production code
2. Improve names, extract helpers, simplify logic
3. Run all tests after every small refactor step — they must stay green
4. Do not add new behavior during refactor

## Cycle Length

Each RED-GREEN-REFACTOR cycle: 1–5 minutes.

If a cycle takes longer:
- The step is too big. Write a simpler test first.
- You're solving too many things at once. Focus on one behavior.

## Rules

- NEVER write production code before a failing test demands it
- NEVER write more than one failing test at a time
- NEVER skip the REFACTOR step — tech debt compounds
- NEVER delete a failing test to make the suite pass
- NEVER write a test that tests implementation rather than behavior

| Excuse | Why it fails |
|---|---|
| "I'll write tests after" | You won't. And the code won't be testable. |
| "This is too simple to test" | Simple untested code becomes complex untested code. |
| "Testing slows me down" | Debugging untested code is what's slow. |
| "I know it works" | Prove it. Write the test. |
| "The interface isn't stable yet" | Then write a test for the behavior, not the interface. |
