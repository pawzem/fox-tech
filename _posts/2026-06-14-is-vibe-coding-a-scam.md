---
layout: post
title: "Is Vibe Coding a scam or is it actually useful?"
date: 2026-06-14
tags: [Java, Design Patterns, DDD, Vibe Coding, LLM]
excerpt: "Looking only at Linkedin it seems that LLM can do it all and there is place for developers any more. I wanted to verify it by vibe coding app on my own and see for myself what is just a hipe and what is a new way of working"
---

Lately I've been sitting too much on the LinkedIn and Reddit. As n result I couldn't really make my mind if LLMs will replace me, or they will become niche technology similarly to what has happened to BlockChain.

Also working in teh corporate environment doesn't help as expectation on the AI adoption are quite high on the other help they need to work in the existing, extremely complex context of the "legacy code" which means that AI is sometimes pretty awesome but at the same time it seems to be more damaging and time-wasting then doing things on my own.

To verify what works and what is not yet quite there I decided to "build" full stack application using LLM exclusively for writing code while limiting my role to an architect and a reviewer.

## Spec driven with event storming

By now we all know that just telling to write new SaaS, make no mistakes and repetitively telling it to fix it doesn't work. And it's  not like I am not using AI on the daily basis, so I knew I need to start from the plan, general sets of guidance and only then I can hope to produce anything useful.

I'm fortunate enough that I have access to domain experts(my parents). Who are running tire exchange company for quite a long time, and they repetitively asked me to write "booking application" for them. For various reason market available solutions are not exactly what they need so a while back we did a Event Storming together to decide what is exactly needed.
I even started to develop it a while back but it tuned out that writing Saas on the evenings is really exhausting, especially if you got small kids in home so I had to drop it after writing most of the backend core domain. So I had initial architecture which I only needed to check again and I could go on for the next stages of the plan generation.

Of course to verify if vibe coding is variable I couldn't resue the code, but I could compare what it proposed to what I wanted as first version of the plan was build from the event storming alone without me adding my own bias to that(more than it was already in teh sticky notes ofc).

And here is my first strong opinion which I manged to confirm with this project.

LLMs as they are now are not gratest modellers.

It didn't spot Party archetype and the design for the reservation core domain was too rigid. SO maybe it would work for just one specific use case but generally would be nightmare to maintain, as it would need a lot of IFs over time, and it wouldn't allow for new business opportunities e.g. generally we should be able to reserve everything not only a tire exchange.

But simple bounded context derived from Event storming(marked with labels on the miro board) plus added supportive domains were generally ok. So even though I had to instruct it what I want for the core design it was generally useful.

Since then, I started using Event storming as my go-to Spec Driven tool in my day job as well as it already has a lot of ways to verify if processes, is a lot easier to review then plain Markdown file and has a lot of tools to spot gaps in the process so it saved me a tone of time already. Even though if ES is generated from the code only it tends to be too technically and requires a bit of fine-tuning after initial generation.

## Initial rule set

Since the goals was to write something maintainable and I don't trust that token prices won't go to the moon next few months. I added also rules which would make project similar to may go-to style for designing software.

So main rules were:
- Everything needs to be verifiable locally, I don't want any on env working fixes. And I want to mirror my local as much to dev and prod as possible.
- Initial tech stack: AWS as cheap as possible but SaaS grade, Lambdas, Cognito, PostgresDB, Java, GraalVM, Spring Monolith, React, Stripe for payments
- Interaction between must go through Facade Services only adn if needed to verify architecture for coupling(more on that later on)
- Preference for projections instead of direct DB read
- No Mockito(I should probably write separate one why I think that it should be niche library when there is on other choice)
- Use good practices from Architects I respect: Eric Evans(DDD building blocks), Adam Bien(AWS SAM setup), Tomasz Ducin(FrontEnd architecture) and after LLM proposed Outbox Pattern I asked it to review plan with Oskar Dudycz guidance

Generally I find DDD to be working superbly with LLMs. DDD put's a lot of focus on language and LLMs are Large Language Models so they should fit together well.
And in my opinion they really do. 

DDD provides limited number of building blocks so LLMs are less likely to hallucinate it's easier for them produce consistent code.
This technique also focuses on code being closer to business and naturally produces easy to read code(at least for me as I am well familiar with the patterns). So it makes it a lot easier to review backend changes e.g. I got Ubiquitous Language automated check, so I don't have to think twice what's the difference between reservation and visit. 
So generally if you didn't already I hugely recommend to read Domain Driven Design by Eric evans as it's more relevant then ever.At least for me. 

## Backend

Generally my package structure looks like this:

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
methods that enforce invariants and emit events — never `setName(...)`. A
fitness test (example 04) fails the build on any JavaBean setter on an
aggregate.

**Controllers are transport only.** `TenantController` binds the request,
calls one service method, maps the DTO to a wire record, returns. If a
response needed a field from another context, the *service* would source it
and return a complete DTO — the controller stays a one-liner per route.

**The stub ships in `contract/`.** `TenantServiceStub` is how *other*
modules' unit tests use the tenant context without booting it — the
no-Mockito convention. 

**Rules are enforced** Rules are protected by either Spring Modulith, ArchUnit, custom test and claude rule if broken multiple times.

**Ports and Adapters** Anything that talks to the outside world — email, SMS, the message bus,
object storage, payments — sits behind a **port** (a plain interface in the
shared kernel). Domain code depends only on the port; the vendor SDK lives in
a swappable **adapter** at the edge. Two house rules make this pleasant
rather than ceremonial.

**3 Tiers of tests** Unit, running in one class only. Story, running on Service level with Fakes and In Memory BDs. Integration, test-containers on whole flow

I used similar setup successfully in the past, and it's proven to me to be awesome for LLMs as well

- Bounded Contexts are confined space so LLM(as well as devs) don't need to jump around the whole project to find out what is happening. Packages are candidates fo microservices so they need to be meaningfully on their own
- If something fails it's easy to spot on what as testing pyramid point precisely to failure point. 
- Whole structure makes it easy to spot where more attention from reviewer is needed. If new policy I just asked is added it's easy to quickly review and approve. But when manifests or arch unit changes I know that my full attention is needed. 
- I know the code style by heart, so I don't need build code context from the scratch to review it. 


## Drift was real
So overall what worked in real life for me worked well for LLMs as well, but it didn't eliminate the need from me to understand the code.

I asked LLM to use Party Archetype and I know how it looks. If I wouldn't, I would end up wit Cargo Culture Archetype.
Naming was right but for new roles LLMs created new tables instead of Party roles. So It wouldn't be flexible at all in the end. Classical, collage level setup.

And it knew what the archetype is, it just got har time following the design at times.

Same goes for other domains. Majority of changes were LGTM but if the structure wouldn't help me to spot the key deviations I would be screwed. LLMS make it easy to believe they know what they are doing with how confident they are but at the same time they are quite confident with going astray. So human in the loop fo coding is not optional and just loops won't cut it for me as the damage could be extremely expansive to fix if some of those changes would hit production and customers would start to consume the code. At least now 6.2026 with Opus 4.8.

## Front End
I would like to tell you a lot about the fronted architecture but truth be told this is the most vibed part of the app, so I cannot really review how clean it is.
I asked Claude to include Tomasz Ducin work as an inspiration. I also got the north star design generated from Stitch so the setup looks reasonable.

- **One feature folder per backend BC.** `features/<bc>/` owns its hooks, components, types, fixtures, tests, and locale strings. Cross-feature reach goes through the feature's `index.ts` — never deep imports. Enforced by `eslint-plugin-boundaries` (the frontend equivalent of `ApplicationModulesTest`).
- **`features/<bc>/api.ts` is the only file that calls the typed OpenAPI client.** Components and hooks never `fetch` directly. Wire types stay generic; domain types are branded IDs + discriminated unions parsed at the API boundary.
- **State by smallest scope.** Server data → TanStack Query (never duplicated in `useState`); URL filters → `useSearchParams`; forms → react-hook-form + Zod; cross-tree → React Context. **No Redux.** Zustand needs an ADR.
- **`/web/shared` is the kernel** — auth adapter (port/adapter pattern, see `web/shared/src/auth/AuthAdapter.ts`), HTTP client, design tokens, headless Radix-based primitives, i18n bootstrap, a11y helpers, OpenAPI codegen target. **Promotion rule:** a thing crosses into `/web/shared` only after three independent uses.
- **Three test tiers** (mirrors backend): unit (Vitest), integration (RTL + MSW), end-to-end smoke (Playwright in `/web/e2e/`). No snapshot tests. MSW handlers live in `features/<bc>/fixtures/`.
- **Strictness:** `tsconfig` runs with `strict`, `exactOptionalPropertyTypes`, `noUncheckedIndexedAccess`, `verbatimModuleSyntax`; ESLint `no-explicit-any` is `error`. `eslint-plugin-jsx-a11y` and `i18next/no-literal-string` are also `error`.

I probably had too much scope for sessions when doing fronted tasks as after they were done I spent a lot of time asking Claude to fix the UI style or add missing features implemented in the backend but completely forgot in the FE.
If I did it again, I wouldn't use north start, but I would generate strict designs with other model e.g. GPT which seems to be better with visuals and teh ask Claude to implement it. 
But generally it is ok much better than I would do it on my own. I am also more open to redesigning most of it if I ever will get som real life customers. When I showed the work to my "Domain Experts" the results are good enough.
Styling is consistent, features are there, and it doesn't take too long LLm to add new features or fix current gaps.

## Infrastructure
By far the most stressful part as I would rather avoid going bankrupt due to AWS bill. 

I am not an expert on the CLI commands, but I know my way around the AWS console and I can design the architecture so it was easy enough for me to tell when I would rather to store content on S3 rather than DB where to put static pages and how I want the code to be run.

The core principles were
- I want this project ot be cheap and it most probably will heave seasonal spikes of usage so serverless is preferred.
- Infra as a Code is a must. I don't want to do some dev firefighting only to same thing on prod. And probably it wouldn't be same ting then anyway. Also, I want to avoid giving any access to changes for the LLM as with series of commands it's difficult to track what is executed.
- Secure by design. IAM roles whenever possible. I don't even use DB passwords in my Spring APP. Secrets cannot leak if there are no secrets. 

So generally it also went well but still first dev deployment took me 30% of whole app development. 
In some cases there were small mistakes in SAM templates in other ENV setup differ from on ENV so it had to be aligned.

Generally at some point I grew too comfortable with Claude proposing changes to the templates and I ended up with unplanned DR on DEV. I got locked out of the DB completely during some dubug session, LLM said that DB needs to be dropped and by the time I remembered that I have backups on DEV as well I ahd to wait an hour for cloud fromation to drop the db, clean whole stack and wait some more for redeployment. Generally fun, do not recommend. 
But it told me something. Even with reasonable SDLC it too easy to trust the LLM. And I I won't understand the code I would not be able to debug it on prod effectively. Sp I would probably would ask LLM to find the root cause. Which could damage the customer data. So this is also the lesson for my professional side. Secure by design should be new standard and touching prod at all by hand should be a red flag. Generally what is not reproducible locally is major bottle nec in the LLM world so instincts should be first to reproduce locally and only then changing anything on any other env. It is a good practice for a while now, nevertheless security is becoming even more important now. 

## Major Changes
Overall not everything was perfect. Besides the points I already brought up I had to switch from GraalVm to SnapStart. If i woudl ahve more time maybe I would spent more time on it but I wasted so much time on the deb of missing classes that given the whole architecture ROI wasn't that great. PRobably I should go with SnapStart from the begining or at least choose Quarkus instead of Spring if I wanted AOT that much.

I also removed custom invoicing in favour of Stripe. Too much of code to maintain and I already had Stripe for payments, so I should have checked Stripe features more before trusting LLM with proposal of integration.
But thanks to that I managed to prove that my backend architecture is solid. Refactoring took only a session on backend and it was easy to spot what was changing due to nice event separation. So it felt surgical. It took a bit more on FE as I also decided to change some administrative views in favour of Stripe as well. But still easier then it would be if I would trust Claude for the Architecture.

## Final Take

I started this article with a question if vibe coding is variable.

And in my opinion it is.

But I don't believe that coding is mostly solved.
LLMs are great 90% of time and frustrating the other 10%(made jup numbers). Human design and oversight is still a must for software which must be maintainable and should bring business opportunities not limitations.
I cannot ignore that I  to do wit LLMs what I couldn't do alone but at the same time it enforces in me a view that if affordable LLMs will be enablers not a job thieves. At least in IT.
Writing first version fo the code was never the toughest part. Figuring out what is needed. Finding out tricky bugs on prod and designing new features with migrations that wouldn't destroy current DB were always the hard part and as is AI is "only" a multiplier not an autopilot

