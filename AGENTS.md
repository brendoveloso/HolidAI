# HolidAI

## Product

HolidAI is a native iOS app that helps users understand which holidays apply to them in Brazil, based on the location and type of their employment contract.

The product is early-stage. Prefer simple solutions that support iteration over premature abstractions.

### Holiday date semantics

- A holiday is a Gregorian civil date, not an instant in time. Its identity and persisted value must contain only year, month, and day, with no time or time zone.
- A holiday returned as `25/12/2026` must remain `25/12/2026` regardless of the device's locale, calendar, time zone, or the user's physical location.
- Do not model or persist holiday dates with `Foundation.Date`. Converting to `Date` is allowed only as an encapsulated, transient bridge for framework APIs, and must not affect business rules, equality, ordering, identity, or persistence.
- The device time zone may be used to determine the user's current civil date ("today"), but never to reinterpret a holiday's date.

## Engineering

- Use Swift and SwiftUI for iOS development.
- Prefer native Apple frameworks and APIs when they are a good fit.
- Follow the existing architecture unless there is a clear reason to change it.
- Before introducing a new dependency, explain why it is preferable to a native or existing solution.
- Do not modify unrelated code while implementing a task.
- After code changes, build the project and report any errors or warnings.
- Add or update tests when changing behavior that can be meaningfully tested.

## Working With Me

I am using this project both to build the product and to improve as a software engineer.

- For meaningful architectural or technical decisions, explain the reasoning and relevant tradeoffs.
- Do not hide important implementation decisions behind generated code.
- When multiple reasonable approaches exist, briefly explain the alternatives before choosing one.
- Keep explanations practical and connected to the codebase rather than turning every task into a tutorial.
