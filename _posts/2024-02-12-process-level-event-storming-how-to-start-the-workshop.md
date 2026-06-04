---
layout: post
title: "Process Level Event Storming: What It Is and How to Start the Workshop"
date: 2024-02-12
tags: [Event Storming, DDD, Workshops]
excerpt: "Big-picture Event Storming gives you alignment but not the detail you need to build software. Here's my flavor of process-level Event Storming — the workshop kickoff, taught through a gas-station role-play that introduces every building block."
image: /assets/img/process-level/12-aggregate-full-process.jpg
---

Have you ever faced difficulties during sprint refinement, trying to get on the same page with your team? Perhaps, after implementing a solution, it turned out that it should look a bit different?

If any of these situations have occurred, or if you're wondering how to define the scope of work without getting too technical, Event Storming might be a great fit for you. Whether you're new to the domain or just need some alignment, the "Big Picture" type of workshop is a valuable tool I've used on several occasions, making my job a lot easier. However, while the high-level overview provides clarity, it lacks the necessary details for implementation. In this blog post series, I'll guide you through conducting such a session, enabling you to translate Event Storming output into your codebase.

The topic is vast, with plenty of materials available to help you tailor the session to your specific needs. Yet, when I first attempted to conduct such a session a few years ago, it proved more challenging than some sources suggested. After conducting multiple sessions and participating in various training workshops, I've developed my own style. This approach has been used successfully in both corporate and startup settings, making process-level Event Storming a key component of my discovery workshops — aiding in the design of accurate backlogs and contributing to the successful delivery of software projects.

If it's the first time you hear about the technique, it could be better if you started from more general materials available [here](https://www.eventstorming.com/). You can also find more sources in the last section. But if you already heard something about it and you would like to deepen your knowledge, I hope you can find valuable information below.

So let me introduce you to my flavor of the method, hoping it will help you adapt it to your needs and elevate your software design game.

Before delving deep into theory, let's embark on the journey of a workshop. In this blog post, we'll initiate the workshop kickoff, with subsequent articles exploring domain exploration and software design based on the Event Storming board.

## Who to invite

First of all, who do you invite to such a session?

That depends, but this time we'll have to go deep into details, so it's better to focus on a specific domain. Ideally you already have an outcome of big-picture Event Storming, so you can invite people interested in specific domains — a wider audience may quickly get bored with topics which don't concern them. But it's possible to skip this step if you're familiar with the domain enough that you can clearly define what you'll be talking about. For example, you just want to add a new feature to your software, so maybe your scrum team plus one or two additional stakeholders like an architect and another technical manager will be enough.

For a commercial workshop I usually asked for key stakeholders such as an Enterprise/Software Architect and some representatives of teams or domain experts that this domain may need to integrate with. They may be managers or experienced employees — it depends.

## Warming up with a story

For me, Event Storming is all about telling the stories from different points of view, so let's start with a story for an introduction. A role play, to be precise.

Imagine that you are the owner of a gas station and you would like to improve the customer experience, possibly by introducing some software — but you're not sure yet. And this is the goal of the training, which we use to cut the possibilities short.

It needs to be a simple topic which everybody knows, so participants can familiarize themselves with the building blocks without thinking too much about the proper solution. Also, this part should not take longer than 5 minutes, as we have the whole workshop to conduct. I know this is a bit fuzzy, but I need you to trust me for a bit. It will become a lot clearer in a few minutes.

So, first things first. What are the factors that let you decide that you even need to refuel?

Some of them may be:

- We notice that we're running low on fuel
- Maybe we have a planned trip and want to start with a full tank
- We'd also take into account which gas stations are near or along the way
- Gas stations often offer discounts for returning customers, so it would be perfect to pick the cheapest one
- Maybe we work for an organisation which can only refuel at certain stations

Ok, this time we don't need to get them all, so this is enough. So what would we do with this information?

## Meet the building blocks

Let me introduce you to the first building block, the **Read Model**.

<figure>
  <img src="{{ '/assets/img/process-level/01-read-models.jpg' | relative_url }}" alt="Five green read-model sticky notes: low amount of fuel, planned trip, gas station location, discounts, fleet obligations." loading="lazy">
  <figcaption>Read Models (green) — the information a driver weighs before deciding to refuel.</figcaption>
</figure>

It is a green post-it which represents the information needed to make a decision.

Colours for each building block are up to you, but it's mandatory to stick to the ones you choose, as it improves readability.

Ok, we know what intel is needed — but who makes the decision?

In this case, the driver.

Great, let's model that!

<figure>
  <img src="{{ '/assets/img/process-level/02-actor-driver.jpg' | relative_url }}" alt="The board now adds a yellow 'Driver' sticky next to the read models." loading="lazy">
  <figcaption>The Actor (yellow) — the Driver, who acts on those read models.</figcaption>
</figure>

This is the second building block, the **Actor**. This may be a specific person or the role which acts upon the read model. We model it with a yellow post-it.

So what does this actor do when they decide that it's time to refuel?

They pull off into the station.

OK.

<figure>
  <img src="{{ '/assets/img/process-level/03-command-pull-off.jpg' | relative_url }}" alt="A blue 'pull off into the station' command sticky is added after the Driver." loading="lazy">
  <figcaption>The Command (blue) — "pull off into the station".</figcaption>
</figure>

This is yet another building block, the **Command**. Represented by a blue sticky, it models exactly what the name suggests.

Great, so what happens next?

Oh, the driver pulls off and starts refuelling.

Wait a second — there isn't anything in between? How do they get in? Maybe there is something which would block them from doing so?

Well, they drive through the driveway and then they decide which distributor to pick. Ok, so here comes the next building block, the **External System**.

<figure>
  <img src="{{ '/assets/img/process-level/04-external-system-driveway.jpg' | relative_url }}" alt="A pink 'driveway' external-system sticky is added after the command." loading="lazy">
  <figcaption>The External System (pink) — the "driveway" the driver passes through.</figcaption>
</figure>

The External System has a really imprecise definition, but long story short, it's something we can put the blame on. So it can be a piece of software, a department, or — like in this case — a physical object.

Ok, so the driver pulls off, goes through the driveway and, once they are in, they pick the distributor.

This is a pivotal point in this process since we finally can act upon it, so let's model it with the next building block.

<figure>
  <img src="{{ '/assets/img/process-level/05-event-arrived.jpg' | relative_url }}" alt="An orange 'Arrived at station' event sticky is added." loading="lazy">
  <figcaption>The Event (orange) — "Arrived at station", the moment we can act upon.</figcaption>
</figure>

The **Event** is a verb in the past tense which models something that happened at a given time and is important to the process. If it triggers process changes or interactions, it would be wise to model it; but if we go too deep we may end up with a lot of noise, so we need to focus on events which relate to our goal. Let's not worry too much about that for now — we will validate and improve the process, so we can work both with too few and too many events. We just don't want to discourage participants from speaking their mind.

So what happens once the driver arrives at the station? Is there anything which always happens when they arrive?

They need to pick a position, as there may be a line to some distributors.

Here goes the next building block, the **Policy**.

<figure>
  <img src="{{ '/assets/img/process-level/06-policy-position.jpg' | relative_url }}" alt="A purple policy sticky is added after the 'Arrived at station' event." loading="lazy">
  <figcaption>A Policy (purple) — how the driver decides which position to take.</figcaption>
</figure>

Policies are rules and habits which happen in the process. They happen after an event and they can follow the template "whenever X then Y" or "immediately after X happens, Y." Policies may be fully automated or driven by actors.

In this case the driver makes the decision, so how do they do it?

Well, depending on the line length and the fuel type available at the distributor.

Let's model that.

<figure>
  <img src="{{ '/assets/img/process-level/07-policy-read-models.jpg' | relative_url }}" alt="Two more read models — 'queue size' and 'fuel types' — feed the policy." loading="lazy">
  <figcaption>The read models behind that decision: queue size and fuel types.</figcaption>
</figure>

What happens next?

After the driver picks the distributor, they drive to the position.

Ok, this could look like this.

<figure class="wide">
  <img src="{{ '/assets/img/process-level/08-pick-distributor.jpg' | relative_url }}" alt="The board grows to include 'pick the distributor' and assuming a position next to it." loading="lazy">
  <figcaption>Modelling "pick the distributor" and assuming a position next to it.</figcaption>
</figure>

Once they are in, if there's an employee at the distributor they can refuel the tank — but if no one is around, the driver can do it themselves.

<figure class="wide">
  <img src="{{ '/assets/img/process-level/09-refuel-policies.jpg' | relative_url }}" alt="Two refuelling policies branch off: an employee refuels, or the driver self-serves." loading="lazy">
  <figcaption>Two refuelling policies — an employee refuels, or the driver does it themselves.</figcaption>
</figure>

Since this is just an example, let's focus only on the bottom one.

Ok, so the employee refuels the tank.

<figure class="wide">
  <img src="{{ '/assets/img/process-level/10-hotspot-refuel.jpg' | relative_url }}" alt="A black 'skipped for now' hotspot sticky parks a discussion; the refuel step is modelled." loading="lazy">
  <figcaption>A Hotspot (black, "skipped for now") parks a discussion for later.</figcaption>
</figure>

Here we've added the black post-it as the **Hotspot**. This could be information which we want to talk about later in the session, or a starting point for some other discussion.

What's next?

When the employee finishes, the tank is set to the requested level.

<figure class="wide">
  <img src="{{ '/assets/img/process-level/11-car-refueled.jpg' | relative_url }}" alt="An orange 'car refueled' event closes this path." loading="lazy">
  <figcaption>The Event "car refueled" — the tank is set to the requested level.</figcaption>
</figure>

Cool, we can stop this process for now. Let me show you what happens next.

Now we need to validate it. There are several ways to do it, but my favourite one is speaking the story out loud — and it needs to be out loud.

This is just how our brain works: once we say it out loud, it's a lot easier to track inconsistencies.

Ok, so I can try:

> Driver drives the car and notices that they're running low on fuel. There's a convenient gas station nearby, so they pull off through the driveway and, once they arrive, they pick the distributor where the employee refuels the car.

Hm, but what if more people were there?

They may decide to leave for another station. Maybe, while they wait in the line, we can offer them hot beverages or show them our promotions.

Then it looks like there's something in between.

The last building block is the **Aggregate**. You can think of it as a state machine or component which is under our control.

So the process we're talking about could look like this.

<figure class="wide">
  <img src="{{ '/assets/img/process-level/12-aggregate-full-process.jpg' | relative_url }}" alt="The complete Event Storming board for the gas-station refuelling process, with the queue modelled as an aggregate and alternative paths drawn as arrows." loading="lazy">
  <figcaption>The full flow — the queue Aggregate ties it together, with alternative paths drawn in.</figcaption>
</figure>

There are a lot of things which we could improve, but this is good enough. Before we take the workshop to the real domain, let's write down how we're going to work.

## The ground rules

<figure>
  <img src="{{ '/assets/img/process-level/building-blocks-legend.jpg' | relative_url }}" alt="A legend of every building block: Read Model, Person/Actor, Command, External System, Aggregate/Component, Event, Policy, Person-Managed Policy and Hot Spot." loading="lazy">
  <figcaption>The building blocks at a glance — the shared grammar for the session.</figcaption>
</figure>

1. **The grammar must be respected.** That means we use the building blocks, and the order of post-its must be as described — e.g. a Command cannot be placed directly after an Event.
2. **Every path must be completed and in a stable state**, so it ends with either a read model or an event.
3. **Every hotspot needs to be addressed.** We either resolve it or mark it for the follow-up session (which doesn't have to be Event Storming).
4. **Every stakeholder needs to be reasonably happy.** In these sessions we want to align, so every possibility should be discussed — even if only to be discarded.

Don't worry if not every participant catches it fully; that's why there's a facilitator in the session. So when we go for the real domain, there's still room for technical questions.

Depending on the group, I often start from the rules and then go for the example — but it depends on whether the group has any analytical or technical background, so they won't be overwhelmed with too many definitions from the start.

That would be it. In the next article we'll explore the real domain, and after that I'll show you how to make software out of it.

## Sources

Below you can find my sources and a list of places I recommend if you're interested in Event Storming:

- [eventstorming.com](https://www.eventstorming.com/)
- [Collaborative Process Modelling with EventStorming — Alberto Brandolini](https://medium.com/@ziobrando/collaborative-process-modelling-with-eventstorming-17ed363650c0)
- [awesome-eventstorming](https://github.com/mariuszgil/awesome-eventstorming)
