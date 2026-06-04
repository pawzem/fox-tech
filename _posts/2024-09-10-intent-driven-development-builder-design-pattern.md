---
layout: post
title: "Intent-Driven Development: My Love-Hate Relationship with the Builder Pattern"
date: 2024-09-10
tags: [Java, Design Patterns, Clean Code]
excerpt: "Design patterns aren't free wins. Walking through modeling a Report entity in Java — from a Lombok @Builder to hand-written constructors — to show why designing for intent beats reaching for a familiar pattern."
---

Have you ever felt irritation from looking at someone else's code after realizing that you have no idea what idea was behind it? Or do most comments you get on your pull requests relate to styling, omitting the domain completely?

Maybe, after those pull requests are merged, it turns out that the code doesn't meet the business requirements — or other developers using it run into bugs for use cases it was never really designed for?

Often a codebase like that gets tagged as "legacy" or "difficult to read." Besides the quality of developers' lives, it can also drive development costs up significantly, as features take more time to build and may require expensive fixes after deployment.

Of course, as a developer, the first drawback is more relatable to me — even though the second one might buy you some time for that mythical refactoring with your manager. Unfortunately, showing your intent clearly is not as easy as it may sound. There are tons of books on clean code and development practices which are usually great, but when applied it turns out they don't resolve the issue or — as I learned the hard way — they can make matters worse if applied incorrectly.

But what does "incorrectly" mean in that context? In my opinion, the main drawback of those resources is that the examples in them apply to a domain the author is familiar with. What makes it harder is that adding the whole context could make the book unreadable, so some simplifications are mandatory. Understanding what the author meant requires experience from the reader, which means entry-level books may turn into a trap if the developers reading them don't have someone experienced nearby to help translate the teachings to their specific project.

And I'm not saying you shouldn't listen to the almighty senior developer on your team. You can — and, in my opinion, should — challenge their way of thinking and their habits even if you're just starting your development journey, as it may lead to solutions neither of you would have thought of.

What worked for me is to focus on intent while designing my part of the code. That means that whenever I reach for a design pattern, before even choosing it, I try to find out what using that pattern suggests and — most importantly — to identify the reasons for change and the effect I'd like to achieve.

## A Report, and what its shape tells you

To show you what I mean, I'd like to focus on the Builder pattern this time. Let's say we need to model the `Report` entity, which represents sets of data points reported to a controlling party. To simplify the example, let's also assume that we have access to all the necessary information; we only need to model the object properly. So that report could look a little bit like this:

```java
public class Report {
    public Report() {
    }
    public String publicId;
    public String resourceId;
    public String internalId;
    public String description;
    public String reportName;
    public Instant creationDate;
    public List<DataPoint> dataPoints;
}
```

Since we have a piece of code, before we go to the construction part, let's take a break and think a little about what we have here:

- We have a **public class**, which suggests it can be used externally by different modules.
- One **public empty constructor** suggests that fields are set outside of the class, since all of them are public.
- **Two sets of IDs** suggest that external parties may have different requirements for them than our system does.
- **Name and description** look like fields that are either human-readable or part of more complex uniqueness verification.
- **Creation date** is either a simple timestamp used for debugging or a field other parties can use to validate the freshness of the report.
- Finally, we have a **list of data points** which can probably be used for some kind of chart or other validation.

Do we need all of those fields? It depends. They may be part of a contract agreement and required by the report recipient. They may be a set of data that uniquely defines a given time frame and system state. Or this can just be the start of a full-blown feature.

It's difficult to reconstruct the entire context from a single class, but even this small piece raises a lot of questions. So clearly defining the intent around this class can make the lives of other developers easier. That's why I generally do not advise starting from defining the fields, as removing or changing them in the future may be difficult or even impossible once this format is propagated far enough. A better approach is to start the implementation from contracts or test cases. But before we go deeper down this rabbit hole of questions, let's assume that this is part of a ready feature and we only want to add construction of the entity.

## Reaching for the builder

Easy enough — let's introduce a helper library, Lombok, which can add some useful decorators. We can even add a test, since we don't want to lower our coverage rate:

```java
@Builder
@Getter
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class Report {
    private String publicId;
    private String resourceId;
    private String internalId;
    private String description;
    private String reportName;
    private Instant creationDate;
    private List<DataPoint> dataPoints;
}
```

```java
@Test
void shouldCreateReportEntityWithNecessaryFields() {
    // given
    final var publicId = "publicId";
    final var resourceID = "resourceID";
    final var internalId = "internalId";
    final var description = "description";
    final var reportName = "reportName";
    final var creationDate = Instant.now();
    final var dataPoints = List.<DataPoint>of();

    // when
    final var report = Report.builder()
        .publicId(publicId)
        .resourceId(resourceID)
        .internalId(internalId)
        .description(description)
        .reportName(reportName)
        .creationDate(creationDate)
        .dataPoints(dataPoints)
        .build();

    // then
    Assertions.assertAll(
        () -> Assertions.assertEquals(publicId, report.getPublicId()),
        () -> Assertions.assertEquals(resourceID, report.getResourceId()),
        () -> Assertions.assertEquals(internalId, report.getInternalId()),
        () -> Assertions.assertEquals(description, report.getDescription()),
        () -> Assertions.assertEquals(reportName, report.getReportName()),
        () -> Assertions.assertEquals(creationDate, report.getCreationDate()),
        () -> Assertions.assertIterableEquals(dataPoints, report.getDataPoints())
    );
}
```

Is it any better? As always, it depends.

- We've changed the fields' and the constructor's visibility to private, so we can no longer change them after construction — which suggests we want control over those changes.
- Maybe we plan to add rules for creation, or there are some invalid combinations. We still have public accessors, and since they're at the class level, it suggests that every field has meaning to whoever receives the entity instance.
- And finally, we have a builder, which suggests that any field here is optional — we can construct the class without actually setting anything.

Ok, but what if that last sentence isn't true? And if that's the case, why did we remove the option to change a value? Is it really fine that we can construct the class with only one field set and call it a perfectly valid entity?

We can resolve that, if it's an issue, in a few different ways. For example, we can add validation in the constructor, or we can introduce factory methods and make the builder available only there. But do we need builders at all if we use factory methods or constructors anyway?

Again, it depends on the complexity of the factory. But let's say that after a review of business requirements, it turns out we need all of the fields except `reportName` and `description`, as they are helpers for the humans who work with the reports. What's more interesting, there's no business logic inside those methods, as we want to ensure that the report does not change the values received from the source of truth. But, as is usually the case, there's one exception: `internalId`. It turns out this ID is used by the database, and we should set a random UUID on report creation — but we shouldn't make it available outside of the entity. (That could be another conversation; let's leave it like this.)

Having those assumptions, we could add a test to reflect them, maybe even some validation — but our `Report` code is kind of ready, right?

We could argue that it is, but let's wait a minute: when would the other developer working on this find out about those requirements? If we're lucky, they could look into the code or the documentation, if we have any. But let's be honest — do you do that for every class you use? If so, it's a bit time-consuming, isn't it? If we skip those steps, we'd find out about a missing value during test execution, which itself takes some time to give feedback. And relying only on the test pipeline has drawbacks of its own: under some circumstances the test case may be removed, or the whole pipeline can be disabled. It's an extreme case, and we'd have bigger troubles than entity-construction refactoring — but this example is meant to show that *how* we write the code is also part of the quality of our entire software.

## Designing for intent

So, how could we rewrite our case to make it better? Long story short, it could look something like this:

```java
public class Report {
    @Getter
    private final String publicId;
    @Getter
    private final String resourceId;
    @Getter(AccessLevel.PRIVATE)
    private final String internalId;
    @Getter
    private final String description;
    @Getter
    private final String reportName;
    @Getter
    private final Instant creationDate;
    @Getter
    private final List<DataPoint> dataPoints;

    public Report(String publicId, String resourceId, String description,
        String reportName, Instant creationDate, List<DataPoint> dataPoints) {
        this.publicId = publicId;
        this.resourceId = resourceId;
        this.internalId = UUID.randomUUID().toString();
        this.description = description;
        this.reportName = reportName;
        this.creationDate = creationDate;
        this.dataPoints = dataPoints;
    }

    public Report(String publicId, String resourceId, Instant creationDate,
        List<DataPoint> dataPoints) {
        this(publicId, resourceId, null, null, creationDate, dataPoints);
    }

    public Report(String publicId, String resourceId, String description,
        Instant creationDate, List<DataPoint> dataPoints) {
        this(publicId, resourceId, description, null, creationDate, dataPoints);
    }

    public Report(String publicId, String resourceId, Instant creationDate,
        List<DataPoint> dataPoints, String reportName) {
        this(publicId, resourceId, null, reportName, creationDate, dataPoints);
    }
}
```

```java
@Test
void shouldCreateReportEntityWithNecessaryFields() {
    // given
    final var publicId = "publicId";
    final var resourceID = "resourceID";
    final var description = "description";
    final var reportName = "reportName";
    final var creationDate = Instant.now();
    final var dataPoints = List.<DataPoint>of();

    // when
    final var report = new Report(publicId,
        resourceID,
        description,
        reportName,
        creationDate,
        dataPoints);

    // then
    Assertions.assertAll(
        () -> Assertions.assertEquals(publicId, report.getPublicId()),
        () -> Assertions.assertEquals(resourceID, report.getResourceId()),
        () -> Assertions.assertEquals(description, report.getDescription()),
        () -> Assertions.assertEquals(reportName, report.getReportName()),
        () -> Assertions.assertEquals(creationDate, report.getCreationDate()),
        () -> Assertions.assertIterableEquals(dataPoints, report.getDataPoints())
    );
}
```

Now we've made sure the methods won't be changed, as the fields are final. The constructor makes sure the proper fields are set, and only valid combinations are available to developers. We could use factory methods, but since the logic is simple and doesn't look likely to change frequently, the constructor does a good enough job. Optional fields are explicitly set as `null` in the constructor, so other developers can at least assume it was intentional and we didn't leave them out by mistake. `internalId` is set in the constructor, so we're sure the logic is valid; we could write a test for that one, but since it strictly relates to the database, an integration test would fit better.

## Takeaways

Of course, this isn't the ultimate `Report` class, and some improvements could still be added — but the goal was to show that even commonly approved patterns may be invalid in some contexts. I also didn't intend to critique the builder pattern: in classes where all fields are indeed optional, it works perfectly. And using ready-made builders from Lombok isn't the only option — with a mix of required and optional fields in DTO classes, we could write our own builder that takes the required parameters in one building block. There are countless options. But if this approach is new to you, I hope you find some uses for it — it certainly made my life as a developer easier.
