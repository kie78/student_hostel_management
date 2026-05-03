---
name: "Build Admin Web Console"
description: "Use when building the Flutter web admin console for this project from the approved admin requirements spec"
argument-hint: "Optional focus area, for example: auth, users screen, universities flow, full implementation"
agent: "agent"
model: "GPT-5 (copilot)"
---

Build or extend the Flutter web admin console for this repository using the canonical project spec in [ADMIN_CONSOLE_REQUIREMENTS.md](../../ADMIN_CONSOLE_REQUIREMENTS.md).

Execution requirements:

- Read [ADMIN_CONSOLE_REQUIREMENTS.md](../../ADMIN_CONSOLE_REQUIREMENTS.md) first and treat it as the source of truth.
- Use the product and API context in [ref.md](../../ref.md) and [integ.md](../../integ.md) when implementing details.
- Build the console in Flutter web only.
- Reuse the existing visual language already present in the project, including the documented palette and `Poppins` typography.
- Use live API integration only. Do not add mock data, fake dashboard metrics, or undocumented admin endpoints.
- Use Clerk authentication and fetch a fresh JWT with `getToken()` before each protected request.
- Add confirmation dialogs before destructive actions.
- Implement loading, empty, success, and error states for all admin workflows you touch.
- Keep changes consistent with the existing codebase structure and styling.

Functional scope to support:

- Admin sign-in
- Protected admin routing
- Dashboard summary
- Users list with role filters
- User inspection
- Suspend user
- Unsuspend user
- Delete user
- Universities list
- Create university
- Landlords list
- Students list
- Logout

Implementation guidance:

- Start from the existing app theme and shared networking patterns already in the repository.
- Prefer reusable admin widgets and services over one-off screen implementations.
- If a full implementation is too large for one pass, complete the highest-value vertical slice first and leave the repo in a runnable, coherent state.
- Validate with the narrowest relevant Flutter checks after edits.

Expected output from the agent:

- Implement the requested admin web console scope directly in the repository.
- Summarize what was built.
- Call out any blockers, missing backend capabilities, or deliberate follow-up work.