## Testing

- Prefer test-first for new behavior and bug fixes: write the failing test, then fix the code.
- Test behavior, not implementation. Tests should survive refactors without changing.
- Each test covers exactly one behavior. Name it: `should [expected result] when [condition]`.
- Follow Arrange-Act-Assert structure. A blank line separates each section.
- Test failure paths: invalid input, authorization failures, validation errors, external-service failures, and boundary values. Do not stop at the happy path.
- Every bug fix must include a regression test that would have failed before the fix.
- Use parameterized/table-driven tests for variations of the same behavior. Do not copy-paste near-identical tests.
- Avoid tautological tests that only verify the mock returns what you told it to. Assert on transformations, side effects, or state changes.
- Mock only external I/O: network calls, filesystem, time, randomness. Avoid mocking internal modules unless necessary.
- Integration tests for API endpoints and database queries. Unit tests for business logic.
- Coverage target: 80%+ on new code. Critical paths (auth, payments, data mutations) should be higher.
- Tests must be deterministic. No random values, no time-dependent assertions without mocking time.
- Each test starts with a clean state. Set up in `beforeEach`, tear down in `afterEach`.
- Run targeted tests after each change. Run the full relevant suite before shipping, committing, or opening a PR.
- Do not skip or disable tests to make the suite green. Fix the test or fix the code.
- IMPORTANT: Never claim tests, builds, lint, or scans passed unless they were actually run. "I think it works" is not verification.
