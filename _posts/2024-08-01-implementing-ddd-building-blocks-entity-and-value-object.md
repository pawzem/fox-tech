---
layout: post
title: "Implementing DDD Building Blocks: Entity and Value Object"
date: 2024-08-01
tags: [DDD, Java, Modeling]
excerpt: "A hands-on look at two core Domain-Driven Design building blocks — Entity and Value Object — modeled through a small tabletop-RPG example in Java, starting from behavior instead of fields."
---

## Introduction

Domain-Driven Design (DDD) has been a popular concept for some time now. However, to see implementation examples, it is often necessary to go through a vast amount of text and other materials. This article aims to refresh your memory on how such building blocks are defined and can be implemented, or to show you how these concepts may look in code.

In this article, I'll demonstrate how to create a basic entity and put basic logic around it to make it somewhat useful. Note that this is not a comprehensive example of the modeling process. As this is quite a complex topic on its own, I'll be acting as both domain expert and developer, using a simple example of implementing tabletop RPG mechanics. These examples should be simple enough for you to draw parallels and hopefully incorporate them into your solutions. If you're interested in how such a process looks from the ground up, I recommend reading about Event Storming and the classic book on that matter.

## Definitions

Let's start by covering the actual topics of this post. To ensure we're all on the same page, let's first define what an Entity is.

Here is how Eric Evans describes it:

> Some objects are not defined primarily by their attributes. They represent a thread of identity that runs through time and often across distinct representations. Sometimes such an object must be matched with another object even though attributes differ. An object must be distinguished from other objects even though they might have the same attributes. Mistaken identity can lead to data corruption. An object defined primarily by its identity is called an ENTITY.
>
> — Eric Evans, *Domain-Driven Design: Tackling Complexity in the Heart of Software* (p. 91)

The rule of thumb is to answer the following question: if I compare two objects with the same attributes and their values are the same, would that mean they are the same object?

An example would be you and me. Even if, due to a strange coincidence, we had the same name and username, we would still be different people. On the other hand, if we were considering website users statistically and we turned out to have the same preferences, then making a distinction between us would be redundant, and that object could be called a Value Object.

Evans defines a Value Object as follows:

> An object that represents a descriptive aspect of the domain with no conceptual identity is called a VALUE OBJECT. VALUE OBJECTS are instantiated to represent elements of the design that we care about only for what they are, not who or which they are.
>
> — Eric Evans, *Domain-Driven Design: Tackling Complexity in the Heart of Software* (p. 97)

## Implementing the first entity

After this lengthy introduction, we can finally start to cover the promised domain.

Let's say we want to create an RPG game. In this game, we create a character and venture through dungeons to defeat foes and gather loot. As inspiration for the behaviors, I'll use Warhammer Fantasy Roleplay, but knowledge of that system is not mandatory to continue reading.

To cover it all, we would need more than just a few paragraphs of a blog post, so this time we'll focus only on basic character creation and behavior.

The character has some basic abilities, skills, classes, race, inventory, and many others. It can also level up, change classes, or even die. To model it all with POJOs would require some time, and since we are not building a 1:1 RPG, some parts of that work wouldn't even be used. (With this approach, techniques like TDD shine especially bright, but they are not mandatory.)

To ensure that we have only what is needed, let's start modeling from behavior, not from properties. At this time, we only need to attack.

So it could look like this:

```java
@Test
void shouldTestFamiliarSkill() {
    // given
    var character = new Character(Map.of(Attribute.WEAPON_SKILL, 20),
        Map.of(Skills.BASIC_WEAPON_ATTACK.name(), 20));
    // when
    var testResult = character.testSkill(Skills.BASIC_WEAPON_ATTACK, Difficulty.EASY);
    // then
    Assertions.assertNotNull(testResult);
}

@Test
void shouldTestUnfamiliarSkill() {
    // given
    var character = new Character(Map.of(Attribute.WEAPON_SKILL, 20),
        Map.of(Skills.BASIC_WEAPON_ATTACK.name(), 20));
    // when
    var testResult = character.testSkill(Skills.RANGE_ATTACK, Difficulty.EASY);
    // then
    Assertions.assertNotNull(testResult);
}

@Test
void shouldTestAttribute() {
    // given
    var character = new Character(Map.of(Attribute.STRENGTH, 20),
        Map.of(Skills.BASIC_WEAPON_ATTACK.name(), 20));
    // when
    var testResult = character.testAttribute(Attribute.STRENGTH, Difficulty.EASY);
    // then
    Assertions.assertNotNull(testResult);
}
```

From the caller's perspective, we only want to know the test result. Since the roll is random for now, we are only testing whether the result is present. With dependency injection, we could inject various dice implementations to actually check the logic. That would be a great thing to do, but this is just an example of the entity, so I wanted to demonstrate modeling starting from the contract instead of from attributes.

## Value objects

To fulfill the contract, we could use some value objects.

The `Attribute` enum clearly points to all possible attributes:

```java
enum Attribute {
    MOVEMENT,
    WEAPON_SKILL,
    BALLISTIC_SKILL,
    STRENGTH,
    TOUGHNESS,
    HIT_POINTS,
    INITIATIVE,
    DEXTERITY,
    INTELLIGENCE,
    WILL_POWER
}
```

The `Difficulty` value object surfaces the ubiquitous language:

```java
enum Difficulty {
    EASY(+10),
    NORMAL(0),
    HARD(-10);

    private final int modifier;

    Difficulty(int modifier) {
        this.modifier = modifier;
    }

    public int getModifier() {
        return modifier;
    }
}
```

The `Skills` enum shows that skills are related to attributes:

```java
enum Skills {
    UNARMED_ATTACK(Attribute.STRENGTH),
    BASIC_WEAPON_ATTACK(Attribute.WEAPON_SKILL),
    RANGE_ATTACK(Attribute.BALLISTIC_SKILL),
    SPELL_PREPARATION(Attribute.WILL_POWER),
    SPELL_CAST(Attribute.INTELLIGENCE),
    JUMP(Attribute.DEXTERITY);

    private final Attribute defaultTestedAttribute;

    Skills(Attribute defaultTestedAttribute) {
        this.defaultTestedAttribute = defaultTestedAttribute;
    }

    public Attribute getDefaultTestedAttribute() {
        return defaultTestedAttribute;
    }
}
```

The `TestResult` value object tells us what the test result actually means:

```java
class TestResult {
    @Getter
    private final boolean isSuccess;
    @Getter
    private final int successLevels;

    private TestResult(boolean isSuccess, int successLevels) {
        this.isSuccess = isSuccess;
        this.successLevels = successLevels;
    }

    public static TestResult of(int testResult) {
        return new TestResult(testResult >= 0, testResult / 10);
    }
}
```

## The Character entity

Finally, the `Character` entity:

```java
class Character {
    private final Map<Attribute, Integer> attributes;
    private final Map<String, Integer> skills;

    Character(Map<Attribute, Integer> attributes, Map<String, Integer> skills) {
        this.attributes = attributes;
        this.skills = skills;
    }

    public TestResult testAttribute(Attribute attribute, Difficulty difficulty) {
        return testAttribute(attribute, difficulty.getModifier());
    }

    public TestResult testSkill(Skills skill, Difficulty difficulty) {
        if (skills.containsKey(skill.name())) {
            return testFamiliarSkill(skill, difficulty);
        }
        return testUnfamiliarSkill();
    }

    private static TestResult testUnfamiliarSkill() {
        return calculateSuccessLevels(1);
    }

    private TestResult testFamiliarSkill(Skills skill, Difficulty difficulty) {
        return testAttribute(skill.getDefaultTestedAttribute(),
            skills.get(skill.name()) + difficulty.getModifier());
    }

    private TestResult testAttribute(Attribute attribute, int modifier) {
        int effectiveValue = attributes.get(attribute) + modifier;
        return calculateSuccessLevels(effectiveValue);
    }

    private static TestResult calculateSuccessLevels(int effectiveValue) {
        return TestResult.of(effectiveValue - Dice.rollD100());
    }
}
```

Of course, we could achieve the same thing with a POJO and the same logic in some kind of service, but here we can be sure that the rules are always followed — e.g. client code cannot modify attribute values. We can also be sure that tests are done consistently.

## Conclusion

This article has introduced basic concepts of Domain-Driven Design, focusing on Entities and Value Objects. We've seen how to model a simple RPG character using these building blocks, ensuring that domain rules are encapsulated within the Entity itself.

While this approach may not be necessary for every project, it provides a solid foundation for more complex domain models. Remember that getting the right model often requires collaboration with domain experts, possibly through techniques like Event Storming.

For those interested in diving deeper into DDD concepts and implementation strategies, I highly recommend Eric Evans' book *Domain-Driven Design: Tackling Complexity in the Heart of Software*. It explains these concepts to a greater extent and provides valuable insights into the modeling process.
