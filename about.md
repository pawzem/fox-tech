---
layout: default
title: About
description: "Paweł Zemła — software architect and team manager writing about Domain-Driven Design, Event Storming and pragmatic software craft."
permalink: /about/
---
<article class="wrap about">
  <section class="about-hero">
    <div class="about-photo">
      <img src="{{ '/assets/img/site/pawel-zemla.jpg' | relative_url }}" alt="Portrait of Paweł Zemła" width="1600" height="1064">
    </div>
    <div class="about-intro">
      <p class="eyebrow">About</p>
      <h1 class="about-name">Paweł Zemła</h1>
      <p class="about-role">Software architect &amp; team manager</p>
      {%- if site.author.linkedin %}
      <a class="btn-secondary" href="{{ site.author.linkedin }}" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden="true"><path d="M20.45 20.45h-3.56v-5.57c0-1.33-.02-3.04-1.85-3.04-1.85 0-2.14 1.45-2.14 2.94v5.67H9.34V9h3.42v1.56h.05c.48-.9 1.64-1.85 3.37-1.85 3.6 0 4.27 2.37 4.27 5.45v6.29zM5.34 7.43a2.06 2.06 0 1 1 0-4.12 2.06 2.06 0 0 1 0 4.12zM7.12 20.45H3.56V9h3.56v11.45zM22.22 0H1.77C.79 0 0 .77 0 1.72v20.56C0 23.23.79 24 1.77 24h20.45c.98 0 1.78-.77 1.78-1.72V1.72C24 .77 23.2 0 22.22 0z"/></svg>
        Connect on LinkedIn
      </a>
      {%- endif %}
    </div>
  </section>

<div class="post-content about-body" markdown="1">
As a software architect and team manager, I have accumulated extensive experience working across various industries — including telecommunications, banking security, and renewable energy. I am a seasoned professional with a deep understanding of both software development and project management.

Overall, I am a dedicated and experienced team player who has worked across multiple industries. My ability to design software systems that meet unique business and technical requirements — together with the soft and business skills necessary for leadership roles — has enabled me to deliver high-quality, pragmatic software solutions that drive business success.

**Fox Tech** is where I write up the practical side of that work: Domain-Driven Design, Event Storming, and the everyday decisions that make code express its intent. These are the field notes I wish I'd had earlier in my career — concrete examples you can draw parallels from and adapt to your own projects.
</div>

  {%- if site.author.linkedin %}
  <aside class="contact-cta">
    <h2>Let's talk</h2>
    <p>Planning a discovery workshop, untangling a tricky domain, or just want to talk shop? LinkedIn is the best place to reach me.</p>
    <a class="btn-primary" href="{{ site.author.linkedin }}" target="_blank" rel="noopener">
      <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" aria-hidden="true"><path d="M20.45 20.45h-3.56v-5.57c0-1.33-.02-3.04-1.85-3.04-1.85 0-2.14 1.45-2.14 2.94v5.67H9.34V9h3.42v1.56h.05c.48-.9 1.64-1.85 3.37-1.85 3.6 0 4.27 2.37 4.27 5.45v6.29zM5.34 7.43a2.06 2.06 0 1 1 0-4.12 2.06 2.06 0 0 1 0 4.12zM7.12 20.45H3.56V9h3.56v11.45zM22.22 0H1.77C.79 0 0 .77 0 1.72v20.56C0 23.23.79 24 1.77 24h20.45c.98 0 1.78-.77 1.78-1.72V1.72C24 .77 23.2 0 22.22 0z"/></svg>
      Connect on LinkedIn
    </a>
  </aside>
  {%- endif %}
</article>
