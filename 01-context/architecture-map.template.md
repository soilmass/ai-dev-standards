# Architecture Map — <PROJECT_NAME>

The system at a glance. Keep this to one screen per section; link to ADRs for the *why*. Update it in the same PR as any change that adds a component, boundary, or external dependency (see `_spines/documentation.md`).

## System overview

<THREE_TO_FIVE_SENTENCES: what the system is, its runtime shape (e.g. web app + API + DB), and where it runs.>

```
<ASCII_DIAGRAM_OF_MAJOR_COMPONENTS_AND_ARROWS_FOR_DATA_FLOW>
```

## Components

| Component | Responsibility | Lives in | Talks to |
|---|---|---|---|
| <COMPONENT_NAME> | <ONE_SENTENCE_RESPONSIBILITY> | <DIRECTORY_OR_SERVICE> | <DOWNSTREAM_COMPONENTS> |
| <COMPONENT_NAME> | <ONE_SENTENCE_RESPONSIBILITY> | <DIRECTORY_OR_SERVICE> | <DOWNSTREAM_COMPONENTS> |

## Boundaries & dependency direction

- <BOUNDARY_RULE, e.g. "UI imports from domain, never the reverse"> — enforced per `03-design/architecture-standards.md`.
- <BOUNDARY_RULE_OR_DELETE_THIS_LINE>

## Data flow

<NUMBERED_STEPS_FOR_THE_PRIMARY_REQUEST_PATH: where a request enters, what validates it, what owns the data, what responds.>

## External dependencies

| Dependency | Used for | Failure mode we tolerate | Owner/dashboard |
|---|---|---|---|
| <SERVICE_OR_API> | <PURPOSE> | <WHAT_HAPPENS_WHEN_IT_IS_DOWN> | <LINK_OR_LOCATION> |

## Environments

| Environment | URL/host | Data | Deploys from |
|---|---|---|---|
| <ENV_NAME> | <WHERE> | <REAL_OR_SEEDED> | <BRANCH_OR_TAG> |
