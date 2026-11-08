# Test quality

## Contents

- Through the public interface
- Anti-patterns

## Through the public interface

A test calls the code the way its callers do and checks what they can observe: a return value, a stored record, a response. It would still pass if the implementation were rewritten with the same behavior. One behavior per test, named for the behavior (`slugify drops punctuation`), not for the function.

## Anti-patterns

| Anti-pattern | What it looks like | Instead |
| --- | --- | --- |
| Implementation-coupled | Asserts which private helper was called, how many times, or in which order; breaks on a refactor that keeps behavior | Assert the result a caller sees |
| Tautological | The expected value is computed with the same formula or function as the code (`expect(total).toBe(price * qty)` where the code is `price * qty`) | Write the expected value as a literal worked out from the spec |
| Horizontal slicing | All tests written first, then all code; the tests describe a design imagined in advance | One behavior at a time: test, red, code, green, next |
| Mock-existence assertion | Asserts that a mock was called, or that a mocked value comes back; passes without any real code | Assert on the real output; mock only the third-party boundary and check what your code does with its answer |
| Passes first time | A new test that is green before the change | It is not testing the change; fix it before pinning |
