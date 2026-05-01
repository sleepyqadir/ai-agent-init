## Testing

- No production code without a test that demanded it. Write the failing test first.
- Test behavior, not implementation. Tests should survive refactors without changing.
- Each test covers exactly one behavior. Name it: `should [expected result] when [condition]`.
- Mock only external I/O: network calls, filesystem, time, randomness. Never mock your own modules.
- Integration tests for API endpoints and database queries. Unit tests for business logic.
- Coverage target: 80%+ on new code. Do not chase 100% on trivial getters or generated code.
- Tests must be deterministic. No random values, no time-dependent assertions without mocking time.
- Each test starts with a clean state. Set up in `beforeEach`, tear down in `afterEach`.
- Run the full test suite before declaring a task complete. A single failing test means the task is not done.
- Do not skip or disable tests to make the suite green. Fix the test or fix the code.
