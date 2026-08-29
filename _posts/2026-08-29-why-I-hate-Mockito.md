---
layout: post
title: "Why I hate Mockito"
date: 2026-08-29
tags: [Java, Testing, Mockito, Unit Tests, Test Coverage]
excerpt: "100% coverage, every gate green, and production still breaks. A small example of how Mockito freezes old contracts inside your tests and quietly waves regressions through."
---

Pretty much every developer have heard about testing pyramid and has some test coverage rules in their repo.
While generally it is good and useful thing I feel that sometimes we forget why those things exist and we focus plainly on chasing the numbers and satisfying "clean code" principles.

One of the symptoms of that approach in my opinion is ubiquity if Mockito and similar mocking frameworks in several programing languages.

I generally believe that it is useful library but its usefulness should be applied to general niche of testing external, not to well thought libraries. And what I saw all over the place over length of my carrier is vastly the opposite thing.

And while most project face the issues I'm going to talk about I rarely see the blame to be put on Mockito and it's application. Most of the time is see the developer being the one getting hit by this blame game while I would rather tu put it on the broken window syndrome and general lack of thoughts due to impeding deadliness.

But first let me explain what the issues and give you some arguments why I generally forbid it all together on projects I have a chance to lead from the ground up. 

# The illusion of 100% coverage

So let's say we want to be extra sure that everything is going to be fine, and we don't want to introduce any regression while bringing on the new features.

The natural solution to this is testing coverage.

So we set the rule to 100% covered and call it a day. 

Developers are smart folks they will write the appropriate things right?

So we got e2e, it, smoke, chaos and of course unit tests.

But we don't want the test to be run for several hours on every run so we want to apply testing pyramid heer as it fairly standard project so the units will be the mian thing.

We write the test, gates are green we deploy to prod and it fails.

How could it be? We got everything covered?

Let me show you

Meet `Multiplier`. It multiplies `a * b`. That's the whole job.

```java
public class Multiplier {

    public double multiply(double a, double b) {
        return a * b;
    }
}
```

And here is `PriceFormatter`, which takes the result and turns it into a price label like `15 PLN`. Two whole numbers multiplied always give a whole number, so casting to `long` is perfectly safe:

```java
public class PriceFormatter {

    private final Multiplier multiplier;

    public PriceFormatter(Multiplier multiplier) {
        this.multiplier = multiplier;
    }

    public String priceLabel(double quantity, double unitPrice) {
        double total = multiplier.multiply(quantity, unitPrice);
        return "%d PLN".formatted((long) total);
    }
}
```

Now the tests. `Multiplier` first — 100% coverage:

```java
class MultiplierTest {

    private final Multiplier multiplier = new Multiplier();

    @Test
    void multipliesSmallOrder() {
        assertEquals(15.0, multiplier.multiply(3, 5));
    }

    @Test
    void multipliesBigOrder() {
        assertEquals(10_001.0, multiplier.multiply(73, 137));
    }
}
```

`PriceFormatter` is a unit, and units must be tested in isolation, right? So we mock the collaborator, just like the common sense says:

```java
@ExtendWith(MockitoExtension.class)
class PriceFormatterTest {

    @Mock
    private Multiplier multiplier;

    @InjectMocks
    private PriceFormatter formatter;

    @Test
    void labelsSmallOrder() {
        when(multiplier.multiply(3, 5)).thenReturn(15.0);

        assertEquals("15 PLN", formatter.priceLabel(3, 5));
    }

    @Test
    void labelsBigOrder() {
        when(multiplier.multiply(73, 137)).thenReturn(10_001.0);

        assertEquals("10001 PLN", formatter.priceLabel(73, 137));
    }
}
```

Everything is green, the coverage report shows 100%, the gate is happy, we ship it.

Then a business requirement lands: big orders get a 5% discount. Someone opens `Multiplier` and does their job:

```java
public double multiply(double a, double b) {
    double result = a * b;
    if (result > 10_000) {
        return result * 0.95; // new business rule: 5% discount on big orders
    }
    return result;
}
```

The contract just changed. The result is not a whole number anymore — `multiply(73, 137)` now returns `9500.95`. 

So of course we alls update the tests.

```java
@Test
void discountsBigOrder() {
    assertEquals(9_500.95, multiplier.multiply(73, 137), 0.001);
}
```

Green. And `PriceFormatterTest`? Also green. 

Of course it is — its `Multiplier` is not the real `Multiplier`. It's a Mockito puppet frozen in time, still answering `10_001.0` like nothing happened. The stubbed answers live in a completely different file than the contract they imitate, and no compiler and no test runner will ever tell you they are now a lie. If ten classes stub `Multiplier`, you have ten copies of the old contract to hunt down by hand — and nothing fails when you miss one.

Meanwhile in production, `priceLabel(73, 137)` happily returns `9500 PLN`. The customer was promised `9500.95`, and 95 groszy silently fell on the floor. Every unit is 100% covered and every unit "works". The system doesn't.

The only thing that catches it is the test nobody was told to write, because both classes were already "fully tested":

```java
class PriceFormatterIntegrationTest {

    private final PriceFormatter formatter = new PriceFormatter(new Multiplier());

    @Test
    void labelsBigOrder() {
        assertEquals("9500.95 PLN", formatter.priceLabel(73, 137));
    }
}
```

```
PriceFormatterIntegrationTest > labelsBigOrder() FAILED
    org.opentest4j.AssertionFailedError: expected: <9500.95 PLN> but was: <9500 PLN>
```

No gate flagged this. Somebody had to sit down, suspect it, and go find it manually.

# But that's not Mockito fault, developers should have written the IT and QA should have tested it manually as well right?

Yes but as I already pointed, now it's easier to forget about it. 

Also since it was really ease to Mock it we didn't need to think that much about the contract of the classes as well.

If it's easy to inject mock, we don't need to put as many thoughts to any anti corruption layers or proper interfacing.

We just add it mock it and move on onto the next task. Examples like that are already in the repo so why bother. I don't have time, and I'm running out of tokens for this mont anyway.

But I agree, this is testing strategy failure not the Mocks itself.

But what about this.

# Let's mock a repository I want one reason for the failure

This time we do everything by the book. No anemic bag of getters and setters — a rich domain entity that guards its own invariants. You simply cannot construct an `Account` without a balance or without a bonus rate:

```java
public class Account {

    private final long id;
    private BigDecimal balance;
    private final BigDecimal bonusRate;

    public Account(long id, BigDecimal balance, BigDecimal bonusRate) {
        this.id = id;
        this.balance = requireNonNull(balance, "balance must not be null");
        this.bonusRate = requireNonNull(bonusRate, "bonusRate must not be null");
    }

    public void applyYearlyBonus() {
        balance = balance.add(bonusRate.multiply(balance));
    }

    // getters
}
```

And the database backs the same rule with its own check:

```sql
CREATE TABLE account (
    id BIGINT PRIMARY KEY,
    balance DECIMAL(19, 2) NOT NULL,
    bonus_rate DECIMAL(5, 2) NOT NULL
);
```

The service takes the account from the repository, applies the change, puts it back. You may notice there is no validation in this method — and that is on purpose. The entity IS the validation. If an `Account` exists, its values are correct. We validate once, at the border, and the rest of the code just does the calculation:

```java
public class BonusService {

    private final AccountRepository repository;

    public BonusService(AccountRepository repository) {
        this.repository = repository;
    }

    public void applyYearlyBonus(long accountId) {
        Account account = repository.find(accountId);
        account.applyYearlyBonus();
        repository.update(account);
    }
}
```

The repository for is plain JDBC for illustration purposes. A SELECT that maps the row into the entity, and an UPDATE going the other way:

```java
public Account find(long id) {
    // SELECT id, balance, bonus_rate FROM account WHERE id = ?
    return new Account(
            results.getLong("id"),
            results.getBigDecimal("balance"),
            results.getBigDecimal("bonus_rate"));
}
```

Now the tests. The entity test covers the calculation and documents the invariants (`rejectsAccountWithoutBonusRate` expects the constructor to throw). 
The repository gets a real integration test, Testcontainers spinning up an actual Postgres, real schema, real rows. 
And the service is a "unit":

```java
@ExtendWith(MockitoExtension.class)
class BonusServiceTest {

    @Mock
    private AccountRepository repository;

    @InjectMocks
    private BonusService service;

    @Test
    void appliesYearlyBonusAndSavesTheAccount() {
        Account account = new Account(42L, new BigDecimal("100"), new BigDecimal("0.05"));
        when(repository.find(42L)).thenReturn(account);

        service.applyYearlyBonus(42L);

        assertEquals(new BigDecimal("105.00"), account.balance());
        verify(repository).update(account);
    }
}
```

They clean code rule is that test should have exactly one reason to fail. 
The entity test has one: the calculation broke. 
The repository test has one: the SQL or the mapping broke. 

Now look at the mocked test above and ask the same question. The calculation is already tested on the entity. The SQL is already tested on the repository. The only thing left is "the service calls the methods that the service calls", restated with `when` and `verify`. 
Its one reason to fail is you refactoring the service. It guards nothing. It just burns time on every pipeline run(and these days tokens too), because your AI agent will happily regenerate it on every change.

But fine, it's green and coverage is happy. 

Then the new feature: the bonus program becomes opt-in. 

Accounts that never joined simply have no bonus rate. So a migration ships:

```sql
ALTER TABLE account ALTER COLUMN bonus_rate DROP NOT NULL;
```

The database check is gone. The entity follows:

```java
public Account(long id, BigDecimal balance, BigDecimal bonusRate) {
    this.id = id;
    this.balance = requireNonNull(balance, "balance must not be null");
    this.bonusRate = bonusRate; // opt-in program: null until the customer joins
}
```

Both places that used to guarantee the invariant dropped it in the same ticket. 

The entity test is updated `rejectsAccountWithoutBonusRate` becomes `allowsAccountWithoutBonusRate`. 

Green. 

The repository test even gets a new case proving that a NULL column maps to a null field just fine. 

Green. 

And `BonusServiceTest`? Untouched and green. Its account is built by hand inside the test, by a person who wrote it back when nulls were impossible. 
The one place that knows what the data actually looks like is the database. Which is exactly the thing we replaced with a mock.

Then the nightly bonus job runs on prod:

```
java.lang.NullPointerException: Cannot invoke "java.math.BigDecimal.multiply(java.math.BigDecimal)"
        because "this.bonusRate" is null
    at Account.applyYearlyBonus(Account.java:20)
    at BonusService.applyYearlyBonus(BonusService.java:14)
```

Every single class did its part and has green tests to prove it. The system still went down at 2 a.m., and again somebody had to find it manually.

Now the counterpart. Here is what the service test should have been from day one. No mocks, a real Postgres in a container, the real schema with the real migration, and the real rows including the one shape nobody imagined:

```java
@Testcontainers
class BonusServiceIntegrationTest {

    @Container
    private static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17");

    private AccountRepository repository;
    private BonusService service;

    @BeforeEach
    void setUp() throws Exception {
        PGSimpleDataSource dataSource = new PGSimpleDataSource();
        dataSource.setUrl(postgres.getJdbcUrl());
        dataSource.setUser(postgres.getUsername());
        dataSource.setPassword(postgres.getPassword());
        try (var connection = dataSource.getConnection();
             var statement = connection.createStatement()) {
            statement.execute("DROP TABLE IF EXISTS account");
            statement.execute("""
                    CREATE TABLE account (
                        id BIGINT PRIMARY KEY,
                        balance DECIMAL(19, 2) NOT NULL,
                        bonus_rate DECIMAL(5, 2) NOT NULL
                    )""");
            statement.execute("ALTER TABLE account ALTER COLUMN bonus_rate DROP NOT NULL");
            statement.execute("INSERT INTO account VALUES (42, 100.00, 0.05)");
            statement.execute("INSERT INTO account VALUES (43, 100.00, NULL)");
        }
        repository = new AccountRepository(dataSource);
        service = new BonusService(repository);
    }

    @Test
    void appliesYearlyBonus() {
        service.applyYearlyBonus(42L);

        assertEquals(new BigDecimal("105.00"), repository.find(42L).balance());
    }

    @Test
    void skipsAccountThatNeverJoinedTheBonusProgram() {
        service.applyYearlyBonus(43L);

        assertEquals(new BigDecimal("100.00"), repository.find(43L).balance());
    }
}
```

Run it against the migrated schema, and it fails immediately, with the exact same exception prod would throw:

```
BonusServiceIntegrationTest > skipsAccountThatNeverJoinedTheBonusProgram() FAILED
    java.lang.NullPointerException: Cannot invoke "java.math.BigDecimal.multiply(java.math.BigDecimal)"
        because "this.bonusRate" is null
```

One test. It exercises the SQL, the row mapping, the entity invariants and the service flow in one go, and every one of its possible failures means something true about the system. 

It would have turned the pipeline red minutes after the migration landed in the PR.
Which means a shorter a feedback loop with response either local or on the CI. 

And the whole setup costs a Docker container that starts in a couple of seconds, which on any modern build machine is a rounding error compared to prod incident, and it's follow up.

# Ok but we got test containers here, we need mocks for the rest. Right?

No.

Then answer for the rest of the issues are either stubs or proper contract tests.

I we structurize our repo but bounded context or features properly

e.g.

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

We can test our Policies and helper class in isolation inside but for everything outside we put a Stub.

The facade is a plain interface:

```java
public interface TenantService {

    TenantDto register(String slug, String displayName);

    TenantDto rename(TenantId id, String newDisplayName);

    Optional<TenantDto> find(TenantId id);
}
```

And the Stub is a real, working in-memory implementation of it provided the tenant context for other BCs. 
Notice it is not a frozen `when(...).thenReturn(...)` answer. It behaves: it remembers what you registered, and it enforces the same rules:

```java
public class TenantServiceStub implements TenantService {

    private final Map<TenantId, TenantDto> tenants = new LinkedHashMap<>();

    @Override
    public TenantDto register(String slug, String displayName) {
        if (tenants.values().stream().anyMatch(tenant -> tenant.slug().equals(slug))) {
            throw new TenantSlugAlreadyTakenException(slug);
        }
        TenantDto tenant = new TenantDto(TenantId.newId(), slug, displayName, TenantStatus.ACTIVE);
        tenants.put(tenant.id(), tenant);
        return tenant;
    }

    // rename() and find() work on the same map
}
```

So the Stub is one of two things. Either a small in-memory version of the facade, like above. Or an even simpler fake that returns constants. 
With no logic inside, it just knows the answers the way a flash card does. 

What keeps the second kind from turning into another Mockito is that those constants are not invented privately by every test that needs them. They are static test cards, published in the contract package right next to the facade. 

The same idea as Stripe's test card numbers:

```java
public final class TenantCards {

    /** Always present in the stub, active — the happy path. */
    public static final TenantDto NORMAL_TENANT = new TenantDto(
            new TenantId(UUID.fromString("00000000-0000-0000-0000-000000000001")),
            "normal-tenant", "Normal Tenant", TenantStatus.ACTIVE);

    /** Always present in the stub, suspended — for the "this should be refused" paths. */
    public static final TenantDto SUSPENDED_TENANT = new TenantDto(
            new TenantId(UUID.fromString("00000000-0000-0000-0000-000000000002")),
            "suspended-tenant", "Suspended Tenant", TenantStatus.SUSPENDED);

    /** Guaranteed to never exist — for the not-found paths. */
    public static final TenantId UNKNOWN_TENANT =
            new TenantId(UUID.fromString("ffffffff-ffff-ffff-ffff-ffffffffffff"));
}
```

The stub ships pre-seeded with them. Downstream nobody programs answers into a mock.
You pick what you need: `NORMAL_TENANT` for the happy path, `SUSPENDED_TENANT` when you want trouble, `UNKNOWN_TENANT` for the not-found branch. 

And since the cards live in the contract package, when the tenant context changes what a suspended tenant means, the cards change in the same commit. 

And every downstream test holding one feels it immediately.

Internally we test if what we produce is the same as stub gets and every other bounded context gets the stub. (They can also get the real thing for IT, but it's not the point now)

The mechanics is one class. The contract written down as executable behavior:

```java
public abstract class TenantServiceContract {

    protected abstract TenantService service();

    @Test
    void registersTenant() {
        TenantDto tenant = service().register("acme", "Acme Corp");

        assertEquals("acme", tenant.slug());
        assertEquals("Acme Corp", tenant.displayName());
        assertEquals(TenantStatus.ACTIVE, tenant.status());
    }

    @Test
    void rejectsDuplicateSlug() {
        service().register("acme", "Acme Corp");

        assertThrows(TenantSlugAlreadyTakenException.class,
                () -> service().register("acme", "Fake Acme"));
    }

    @Test
    void renamesTenant() {
        TenantDto tenant = service().register("acme", "Acme Corp");

        service().rename(tenant.id(), "Acme Holdings");

        assertEquals("Acme Holdings", service().find(tenant.id()).orElseThrow().displayName());
    }

    @Test
    void cannotRenameUnknownTenant() {
        assertThrows(IllegalStateException.class,
                () -> service().rename(TenantId.newId(), "Ghost Corp"));
    }
}
```

Subclasses supply the implementations. The real one runs it against a real Postgres:

```java
@Testcontainers
class TenantServiceImplTest extends TenantServiceContract {

    @Container
    private static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17");

    private TenantService service;

    @BeforeEach
    void setUp() throws Exception {
        // real schema in the container, service wired with the real repository
        service = new TenantServiceImpl(new TenantRepository(dataSource));
    }

    @Override
    protected TenantService service() {
        return service;
    }
}
```

And the stub runs the exact same suite in memory:

```java
class TenantServiceStubTest extends TenantServiceContract {

    private final TenantServiceStub stub = new TenantServiceStub();

    @Override
    protected TenantService service() {
        return stub;
    }
}
```

And when somebody really needs the real thing rather than the stub, the answer is still not Mockito.

It is the real implementation with in-memory variants of its dependencies. 

`TenantRepository` is an interface with two implementations, the JDBC one and an in-memory one, so the same contract suite gets a third run.

```java
class TenantServiceInMemoryTest extends TenantServiceContract {

    private final TenantService service = new TenantServiceImpl(new InMemoryTenantRepository());

    @Override
    protected TenantService service() {
        return service;
    }
}
```

Meanwhile in the billing context nobody mocks anything. You take the stub and use it like the real thing.

```java
// No @Mock, no when(), no verify()
class InvoiceServiceTest {

    private final TenantServiceStub tenants = new TenantServiceStub();
    private final InvoiceService invoices = new InvoiceService(tenants);

    @Test
    void printsInvoiceHeaderForTenant() {
        TenantDto tenant = tenants.register("acme", "Acme Corp");

        assertEquals("Invoice for Acme Corp: 100.00 PLN",
                invoices.invoiceHeader(tenant.id(), new BigDecimal("100.00")));
    }

    @Test
    void printsInvoiceHeaderForWellKnownTenant() {
        assertEquals("Invoice for Normal Tenant: 250.00 PLN",
                invoices.invoiceHeader(TenantCards.NORMAL_TENANT.id(), new BigDecimal("250.00")));
    }

    @Test
    void refusesInvoiceForUnknownTenant() {
        assertThrows(IllegalStateException.class,
                () -> invoices.invoiceHeader(TenantCards.UNKNOWN_TENANT, new BigDecimal("250.00")));
    }
}
```

Then if we change contract our Stub tests fails and if the changes are meaningful for other contexts changes to the Stub propagate test failures outside.

Imagine slugs become case-insensitive, or `rename` starts returning the old name, or registration starts in `SUSPENDED` until activation. 

When you change the implementation, `TenantServiceImplTest` goes red, you fix the contract suite — and now `TenantServiceStubTest` is red until the stub follows. 

One fix, in one place, shipped by the context that owns the rule. And the moment the stub starts answering differently, every consuming context's tests run against the new reality. `InvoiceServiceTest` breaks only if the change actually matters to billing. Compare that with hunting down every `when(tenantService.find(...))` scattered across the repo.

Just like we do with contract tests on our API but here on the context level. Which is exactly what we want as BC is candidate for extraction anyway(just a candidate I'm not saying you should do it blindly).

# How would first example would look like then?

1. If cross BC then contract testing with stubs preferably through BC facade
2. If same BC but separate responsibility. I would probably architectured it to be truly independent and tested orchestration/choreography layer with integration test
3. If nesting is the cleanest option and I have control over it. Then I would probably add some unit tests but tested overlay with real nested class.
4. If nesting is the cleanest option and I don't have control over it. Then I would write thin anti corruption layer and treated it as under control thing then. Mayebe with stub for this foreign thing.

# So do you drop Mockito everywhere you go?

Not really. There is rarely any point in clearing the battle proven codebase from evey Mockito tests. 

Even if doable, usually there is better stuff to do, and we can add e2e tests for circuital flows. 

But I do put an extra attention to code review on those problems when I notice any mocks in the PR, and it is easier for me to disallow mocks form the start on the new stuff.
Especially in teh LLM era. Mockito makes it too easy for LLM to make wrong assumptions. 
As well as fix in the Stub is fix in one place, fix in the mocks cascade across the repo so I feel that I wast less token in that way. Especially on find out the connections. I was saved by facade tests multiple times already.

All the code from this article — both failing examples and the stub/contract-test setup — is in the companion repo: [github.com/pawzem/IHateMockitoExamples](https://github.com/pawzem/IHateMockitoExamples). The build is red on purpose; the two failing tests are the whole point.

Hope that the article was useful to you and if I've sent it to you over the code review then wow. I didn't expect you will actually read it thanks! :D

# References

- Companion repo with all the code from this article (the build is red on purpose): [github.com/pawzem/IHateMockitoExamples](https://github.com/pawzem/IHateMockitoExamples)

### Ai disclaimer
Opinions are entirely mine. Text is also mine(mostly, I did as well some styling). Code was generated by an AI entirely but with exact details what should be in there.