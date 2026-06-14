---
layout: post
title: "Is Vibe Coding a scam or is it actually useful?"
date: 2026-06-14
tags: [Java, Design Patterns, DDD, Vibe Coding, LLM, AWS, Serverless, Spring]
excerpt: "Looking only at LinkedIn it seems that LLMs can do it all and there is no place for developers any more. I wanted to verify it by vibe coding an app on my own and see for myself what is just a hype and what is a new way of working"
---

Lately I've been sitting too much on LinkedIn and Reddit. As a result I couldn't really make up my mind if LLMs will replace me, or they will become a niche technology similarly to what has happened to blockchain.

Also working in the corporate environment doesn't help as expectations on AI adoption are quite high; on the other hand, they need to work in the existing, extremely complex context of the "legacy code" which means that AI is sometimes pretty awesome but at the same time it seems to be more damaging and time-wasting than doing things on my own.

To verify what works and what is not yet quite there I decided to "build" a full stack application using an LLM exclusively for writing code while limiting my role to an architect and a reviewer.

On the tooling side, I used Claude Code with Opus (~4.8). The context I gave it was quite large: a `CLAUDE.md` full of rules that I decorated with new ones whenever Claude made the same mistake twice, plus a `README.md` and architecture docs with more details. Quite a lot, but I wanted to optimize it only if needed, and that wasn't the case as the other architecture decisions were optimization enough.

To set the scale before diving in: it's a multi-tenant booking SaaS — generic enough to reserve anything, not just one vertical. A Spring Boot 4 / Java 25 modular monolith on the backend, three React SPAs on the front, AWS serverless underneath, and it all runs end-to-end locally on Docker Compose + LocalStack (the real AWS rollout is a deliberately later phase). By the time I wrote this it was roughly three-quarters through the implementation plan — enough to have real opinions.

## Spec driven with event storming

By now we all know that just telling it to write a new SaaS, make no mistakes and repeatedly telling it to fix it doesn't work. And it's not like I am not using AI on a daily basis, so I knew I needed to start from a plan, general sets of guidance and only then I can hope to produce anything useful.

I'm fortunate enough that I have access to domain experts (my parents), who have been running a tire exchange company for quite a long time and have repeatedly asked me to write a "booking application" for them. For various reasons the market-available solutions are not exactly what they need so a while back we did an Event Storming together to decide what is exactly needed.
I even started to develop it a while back but it turned out that writing SaaS in the evenings is really exhausting, especially if you have small kids at home so I had to drop it after writing most of the backend core domain. So I had an initial architecture which I only needed to check again and I could go on to the next stages of the plan generation.

Of course to verify if vibe coding is viable I couldn't reuse the code, but I could compare what it proposed to what I wanted as the first version of the plan was built from the event storming alone without me adding my own bias to that (more than it was already in the sticky notes ofc).

And here is my first strong opinion which I managed to confirm with this project.

LLMs as they are now are not the greatest modellers.

It didn't spot the Party archetype and the design for the reservation core domain was too rigid. So maybe it would work for just one specific use case but generally would be a nightmare to maintain, as it would need a lot of IFs over time, and it wouldn't allow for new business opportunities e.g. generally we should be able to reserve everything not only a tire exchange.

But the simple bounded contexts derived from Event Storming (about ten lanes on the Miro board, which became the contexts) plus a few added supportive domains were generally ok. So even though I had to instruct it what I wanted for the core design it was generally useful.

Since then, I started using Event Storming as my go-to Spec Driven tool in my day job as well, as it already has a lot of ways to verify the processes, is a lot easier to review than a plain Markdown file and has a lot of tools to spot gaps in the process so it saved me a ton of time already. Even if ES is generated from the code only it tends to be too technical and requires a bit of fine-tuning after initial generation.

## Initial rule set

Since the goal was to write something maintainable and I don't trust that token prices won't go to the moon in the next few months, I also added rules which would make the project similar to my go-to style for designing software.

So main rules were:
- Everything needs to be verifiable locally, I don't want any on-env working fixes. And I want to mirror my local to dev and prod as much as possible.
- Initial tech stack: AWS, as cheap as possible but SaaS-grade — Lambda, Cognito, Aurora PostgreSQL Serverless v2, Java 25 / Spring Boot 4 as a modular monolith (Spring Modulith), GraalVM native image (I'll come back to this one), React, Stripe for payments
- Interactions between modules must go through Facade Services only and if needed I can verify the architecture for coupling (more on that later on)
- Preference for projections instead of direct DB read
- No Mockito (I should probably write a separate one on why I think that it should be a niche library when there is no other choice)
- Use good practices from Architects I respect: Eric Evans (DDD building blocks), Arlow & Neustadt (the Party/Asset archetypes), Adam Bien (AWS SAM setup), Tomasz Ducin (frontend architecture), and after the LLM proposed the Outbox Pattern I asked it to review the plan with Oskar Dudycz's guidance

Generally I find DDD to be working superbly with LLMs. DDD puts a lot of focus on language and LLMs are Large Language Models so they should fit together well.
And in my opinion they really do. 

DDD provides a limited number of building blocks so LLMs are less likely to hallucinate, and it's easier for them to produce consistent code.
This technique also focuses on code being closer to business and naturally produces easy to read code (at least for me as I am well familiar with the patterns). So it makes it a lot easier to review backend changes e.g. I have an automated Ubiquitous Language check, so I don't have to think twice about the difference between reservation and visit. 
So generally if you didn't already I hugely recommend reading Domain Driven Design by Eric Evans as it's more relevant than ever. At least for me.

One meta-rule turned out to matter more than any single pattern: the architecture lives in three "binding-contract" docs — backend, frontend, infra — and anything that deviates from them either gets fixed or earns an ADR (Architecture Decision Record; eleven so far). The LLM reads those docs, the build enforces them, and when Claude breaks the same rule twice the fix is a new line in `CLAUDE.md` — not another round of code review. That loop — docs the model reads, gates the build runs, rules I add on repeat offenses — is the real reason a partly vibe-coded project stayed maintainable. 

## Backend

Generally my package structure looks like this (`tenant` here is illustrative; the real contexts are booking, schedule, subscription, cancellation and a dozen others):

```
shared/identity/TenantId.java        a typed id (shared-kernel value object)
tenant/
├── contract/                        ← the ONLY public package
│   ├── package-info.java                @NamedInterface("contract")
│   ├── TenantService.java               the facade: commands + queries
│   ├── TenantServiceStub.java           in-memory impl for other modules' tests
│   ├── TenantDto.java                    read-side view returned by the service
│   ├── TenantStatus.java
│   ├── TenantRegistered.java            integration events
│   ├── TenantRenamed.java
│   ├── RegisterTenantRequest.java       HTTP wire records
│   ├── TenantResponse.java
│   └── TenantSlugAlreadyTakenException.java
├── Tenant.java                      ← aggregate            (package-private)
├── TenantServiceImpl.java           ← @Transactional impl  (package-private)
├── TenantRepository.java            ← Spring Data JDBC      (package-private)
├── TenantController.java            ← REST transport        (package-private)
└── package-info.java                   @ApplicationModule(allowedDependencies)
```

### The ideas

**One facade, and it's also the read model.** Commands (`registerTenant`,
`rename`, `suspend`) and queries (`findById`, `findAll`) live on the same
`TenantService`. There's no separate read-model interface or view-projection
type — the service is the read side. One thing to learn, one thing to stub.

**Default-closed visibility.** The aggregate, repository, impl, and
controller are all package-private. A consumer literally cannot name
`Tenant` or `TenantRepository`. Things get promoted to `public` only when a
test outside the package proves it needs them. This is what makes the
boundary real rather than aspirational — and it's why an AI editing a sibling
module *can't* accidentally couple to tenant internals: the types aren't on
its menu.

**Rich aggregate, no setters.** `Tenant` changes state through command
methods that enforce invariants and emit events — never `setName(...)`. An
ArchUnit fitness test (`NoPublicSettersInAggregatesTest`) fails the build on
any single-arg JavaBean setter on an aggregate — multi-arg command methods
stay legal.

**Controllers are transport only.** `TenantController` binds the request,
calls one service method, maps the DTO to a wire record, returns. If a
response needed a field from another context, the *service* would source it
and return a complete DTO — the controller stays a one-liner per route.

**The stub ships in `contract/`.** Every context ships an in-memory
`XxxServiceStub` next to its interface, so *other* modules' tests wire a real
fake instead of mocking — the no-Mockito convention. Shared fakes like
`StubStripePort`, `StubEmailSender`, `FakeClock` and `EventBridgeFake` live in
a `:platform:testing` module. 

**Rules are enforced, not requested.** The boundaries above are checked on every build: `ApplicationModules.verify()` (Spring Modulith) for module dependencies, ArchUnit fitness tests for the aggregate/controller rules, and a `check-ubiquitous-language` script that fails CI on banned synonyms (it literally rejects `Appointment`, `TimeBox`, `EndUser`). Code review catches the rest — and repeat offenders become a new rule in `CLAUDE.md`.

**Ports and Adapters.** Anything that talks to the outside world — email, SMS,
the message bus, object storage, identity, payments — sits behind a **port**: a
plain interface in the shared kernel (`EmailSender`, `SmsSender`, `StripePort`,
`OutboxWriter`, …). Domain code depends only on the port; the vendor SDK lives
in a swappable **adapter** at the app edge. The payoff is concrete: the exact
same domain code runs against an in-memory fake in tests, against
LocalStack / Keycloak / Mailpit locally, and against EventBridge / Cognito / SES
in production — I just swap the adapter. That single decision is what makes
"everything verifiable locally" actually true instead of aspirational.

**Projections, not cross-schema joins.** A context never reads another
context's tables. When booking needs schedule data it keeps its own local
projection, fed by domain events — so each context stays a real candidate for
extraction into its own service later (there's an ADR specifically for
"projection over cross-schema join").

**Outbox over dual writes.** Cross-context events aren't fired from a
post-commit hook that can vanish if the process dies. They're appended to an
`outbox_event` table in the *same* JDBC transaction as the aggregate write; a
dispatcher polls it with `FOR UPDATE SKIP LOCKED`, publishes to EventBridge
with backoff, and dead-letters what won't go. A chaos test kills the process
mid-publish to prove no loss and no duplicates. (Oskar Dudycz's posts are the
reference here.)

**Three tiers of tests.** *Unit* runs in a single class with an in-memory
repository and stubs, no Spring — a policy or an aggregate invariant. *Story*
boots the service with `@SpringBootTest`, a real Postgres via Testcontainers,
and stubbed sibling contexts; it reads like a use case. *Integration*
(`fullflow/`) drives the whole thing against a Liquibase-migrated DB. ~600
tests across the monorepo, and the pyramid points straight at the culprit: a
red unit test is a domain bug, a red story test is wiring, a red full-flow test
is integration.

I'd used a similar setup successfully before, and it turned out to be just as good for working with an LLM:

- Bounded Contexts are confined spaces so LLMs (as well as devs) don't need to jump around the whole project to find out what is happening. Packages are candidates for microservices so they need to be meaningful on their own
- If something fails it's easy to spot what, as the testing pyramid points precisely to the failure point. 
- The whole structure makes it easy to spot where more attention from a reviewer is needed. If a new policy I just asked for is added it's easy to quickly review and approve. But when manifests or arch unit changes I know that my full attention is needed. 
- I know the code style by heart, so I don't need to build code context from scratch to review it. 


## Drift was real
So overall what worked in real life for me worked well for LLMs as well, but it didn't eliminate the need for me to understand the code.

I asked the LLM to use the Party archetype (Arlow & Neustadt's *Enterprise Patterns* — `Party`, `PartyRole`, `Asset`) and I know how it's supposed to look. If I didn't, I'd have ended up with a cargo-cult copy of it.
And in places that's exactly what happened: the naming was right, but for new roles it kept spinning up dedicated tables instead of `PartyRole` rows. The clearest case was admin grants — it created a separate `admin_tenant_grant` table. Here's the honest twist: that one turned out to be *defensible* (platform-scoped admins genuinely sit outside a single tenant's Party graph), so it earned a written rationale instead of a revert. But I only knew to ask the question because I knew the archetype. Get it wrong and you get a rigid, college-project schema that needs a new `IF` for every requirement.

And it knew what the archetype is, it just had a hard time following the design at times.

Same goes for other domains. The majority of changes were LGTM but if the structure wouldn't help me to spot the key deviations I would be screwed. LLMs make it easy to believe they know what they are doing with how confident they are but at the same time they are quite confident while going astray. So a human in the loop for coding is not optional and just loops won't cut it for me as the damage could be extremely expensive to fix if some of those changes would hit production and customers would start to consume the code. At least now, 6.2026, with Opus 4.8.

## Front End
I would like to tell you a lot about the frontend architecture but truth be told this is the most vibed part of the app, so I cannot really review how clean it is.
I asked Claude to lean on Tomasz Ducin's frontend principles — *stable boundaries, volatile internals; type-driven design; vertical features over horizontal layers; composition over abstraction; mechanical enforcement over convention*. For the visuals I generated a north-star design with Stitch and then turned it into a small custom design system (I call it "Terracotta Concierge"), so the setup looks reasonable.

- **One feature folder per backend bounded context (BC).** `features/<bc>/` owns its hooks, components, types, fixtures, tests, and locale strings. Cross-feature reach goes through the feature's `index.ts` — never deep imports. Enforced by `eslint-plugin-boundaries` (the frontend equivalent of `ApplicationModulesTest`), with `dependency-cruiser` catching cycles weekly. 48 of these across the three SPAs.
- **`features/<bc>/api.ts` is the only file that calls the typed OpenAPI client.** Components and hooks never `fetch` directly. Wire types stay generic; domain types are branded IDs + discriminated unions (e.g. `BookingId` is a branded `string`, `BookingState` is `'PICKED' | 'CONFIRMED' | 'CANCELLED'`) parsed from the wire at the API boundary.
- **State by smallest scope.** Server data → TanStack Query (never duplicated in `useState`); URL filters → `useSearchParams`; forms → react-hook-form + Zod; cross-tree → React Context. **No Redux.** Zustand needs an ADR.
- **`/web/shared` is the kernel** — auth adapter (port/adapter pattern, see `web/shared/src/auth/AuthAdapter.ts`: `OidcClientTsAdapter` locally, `CognitoAmplifyAdapter` in prod), HTTP client, design tokens, headless Radix-based primitives, i18n bootstrap, a11y helpers, OpenAPI codegen target. **Promotion rule:** a thing crosses into `/web/shared` only after three independent uses — two uses get a copy-paste, the third earns promotion.
- **Three test tiers** (mirrors backend): unit (Vitest), integration (RTL + MSW), end-to-end smoke (Playwright in `/web/e2e/`). No snapshot tests. MSW handlers live in `features/<bc>/fixtures/`. Accessibility is a gate too — `@axe-core/playwright` plus a Lighthouse a11y budget ≥ 90.
- **Strictness:** `tsconfig` runs with `strict`, `exactOptionalPropertyTypes`, `noUncheckedIndexedAccess`, `verbatimModuleSyntax`; ESLint `no-explicit-any` is `error`. `eslint-plugin-jsx-a11y` and `i18next/no-literal-string` are also `error`.

I probably had too much scope per session on frontend tasks — after they were "done" I spent a lot of time asking Claude to fix the UI style or add features that existed in the backend but were completely forgotten in the frontend (FE).
If I did it again, I wouldn't use north star, but I would generate strict designs with another model e.g. GPT which seems to be better with visuals and then ask Claude to implement it. 
But generally it is ok, much better than I would do it on my own. I am also more open to redesigning most of it if I ever get some real life customers. When I showed the work to my "Domain Experts" the results were good enough.
Styling is consistent, features are there, and it doesn't take too long for the LLM to add new features or fix current gaps.

## Infrastructure
By far the most stressful part as I would rather avoid going bankrupt due to an AWS bill. 

I am not an expert on CLI commands, but I know my way around the AWS console and I can design the architecture so it was easy enough for me to tell when I would rather store content on S3 rather than DB, where to put static pages, and how I want the code to be run.

The core principles were
- I want this project to be cheap and it most probably will have seasonal spikes of usage so serverless is preferred.
- Infra as Code is a must. I don't want to do some dev firefighting only to do the same thing on prod. And probably it wouldn't be the same thing then anyway. Also, I want to avoid giving any access to changes for the LLM as with a series of commands it's difficult to track what is executed.
- Secure by design. IAM roles wherever possible — the Spring app doesn't even hold a DB password; it authenticates to Aurora with an IAM token (via `aws-jdbc-wrapper`), so there's nothing to leak. Tenant isolation is enforced in the database with Row-Level Security (RLS), and a coverage test (`RlsCoverageTest`) fails the build if any tenant-scoped table is missing its policy. The secrets that must exist (Stripe keys) live in Secrets Manager and are read once at startup. Secrets cannot leak if there are no secrets. 

In practice that meant the whole thing ran locally before AWS was even in the picture: Docker Compose brings up Postgres, LocalStack (S3, SNS, SQS, EventBridge, Secrets Manager), Keycloak standing in for Cognito, and Mailpit for email. Same code, different adapters; the AWS rollout is a deliberately separate, later phase.

So generally it also went well but still the first dev deployment took me 30% of the whole app development. 
In some cases there were small mistakes in SAM templates, in others the ENV setup differed from one ENV to another so it had to be aligned.

Generally at some point I grew too comfortable with Claude proposing changes to the templates and I ended up with an unplanned DR — disaster recovery — drill on DEV. I got locked out of the DB completely during a debug session, the LLM said the DB needed to be dropped, and by the time I remembered I had backups on DEV too, I'd already waited an hour for CloudFormation to drop the DB, tear the whole stack down and redeploy. Generally fun, do not recommend. (Dev has deletion-protection off on purpose so it's cheap to rebuild; prod has it on — an asymmetry you only really appreciate after an episode like this.) 
But it told me something. Even with a reasonable SDLC (software delivery lifecycle) it's too easy to trust the LLM. And if I don't understand the code I would not be able to debug it on prod effectively. So I would probably ask the LLM to find the root cause. Which could damage the customer data. So this is also the lesson for my professional side. Secure by design should be the new standard and touching prod at all by hand should be a red flag. Generally what is not reproducible locally is a major bottleneck in the LLM world so instincts should be first to reproduce locally and only then change anything on any other env. It has been good practice for a while now, nevertheless security is becoming even more important now. 

## Major Changes
Overall not everything was perfect. Besides the points I already brought up I had to switch from GraalVM to SnapStart. I wasted so much time feeding GraalVM reachability metadata for the reflection it couldn't see at build time — the classic native-image "missing classes at runtime" tax — that, given the whole architecture, the ROI just wasn't there. I wrote it up as an ADR (`infra-0005-snapstart-over-graalvm`) and moved every Lambda to the managed `java25` runtime with SnapStart instead. Cold starts are fine and I got my evenings back. Probably I should have gone SnapStart from the beginning, or picked Quarkus over Spring if I wanted AOT that badly.

I also removed custom invoicing in favour of Stripe — a whole monthly `IssueInvoicesJob` cron plus the admin views around it. Too much code to maintain when I already had Stripe for payments. Now Stripe is the source of truth and a webhook listener just mirrors its invoices into a projection. I should have read up on Stripe's features more before letting the LLM propose a from-scratch integration.
One honest caveat the LLM kept glossing over: the Stripe webhook round-trip is the one thing I *can't* gate in CI — it needs a real, signed delivery — so I verify it by hand (`./gradlew verifyStripeWebhook`) before calling anything billing-related done. A good reminder that "all green" is not the same as "all covered".
But the refactor did prove the backend architecture is solid: it took a single session on the backend, and the event separation made it easy to see exactly what changed — it felt surgical. The frontend took a bit longer, since I also moved some admin views over to Stripe's hosted portal. Still far easier than if I'd let Claude own the architecture in the first place.

## Final Take

I started this article with a question if vibe coding is viable.

And in my opinion it is — I have a real multi-tenant SaaS I could never have finished solo on weeknights, it runs end-to-end locally, and the parts that matter are covered by tests and enforced by the build.

But I don't believe that coding is mostly solved.
LLMs are great 90% of the time and frustrating the other 10% (made-up numbers, but they feel about right). Human design and oversight is still a must for software that has to stay maintainable and open up business opportunities rather than wall them off. The thing that kept this project honest wasn't the model — it was everything around it: the binding-contract docs, a build that fails on a broken boundary, and a new rule every time Claude repeated a mistake.
I can't ignore that I did, with LLMs, what I couldn't do alone — but it also reinforces a view: as long as they stay affordable, LLMs are enablers, not job thieves. At least in IT.
Writing the first version of the code was never the toughest part. Figuring out what's actually needed, finding tricky bugs in prod, and designing migrations that don't destroy the current DB — that was always the hard part, and it still is. The LinkedIn version says there's no room left for developers; my repo says the opposite. AI is a multiplier, not an autopilot — and someone still has to steer.

