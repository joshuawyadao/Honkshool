# Documentation

Honkshool is an experimental iPhone app with source installation and a small offline catalog. Start with the guide for what you want to do. The [repository README](../README.md) gives the visual overview.

## Try the app

| Guide | Use it for |
| --- | --- |
| [Getting started](Getting-Started.md) | Requirements, simulator launch, private signing, and installing a development build |
| [User guide](User-Guide.md) | Choosing a Nap Plan, confirming and starting, audio/alarm controls, and history |
| [Troubleshooting](Troubleshooting.md) | Installation, expired plans, permission failures, audio, and history problems |
| [Privacy and local data](Privacy.md) | Stored data, system permissions, backups, and current deletion/export limits |
| [Ten-nap personal trial](Ten-Nap-Trial.md) | Evaluate ordinary use and keep observations private |
| [Blank trial log](Ten-Nap-Trial-Log.template.md) | Copy to a private ignored location; never fill out the tracked template |

## Contribute or understand the code

| Guide | Owns |
| --- | --- |
| [Contributing](../CONTRIBUTING.md) | Contribution workflow and public-data expectations |
| [Development](Development.md) | Source/script map, verification commands, test boundaries, and CI |
| [Architecture](Architecture.md) | Module ownership, dependency direction, and platform seams |
| [Nap-planning domain](Nap-Planning-Domain.md) | Identity, fixed plans, actual playback, completion, resume, and persistence contracts |
| [Feasibility evidence](Feasibility-Spike.md) | Diagnostic console, historical and current device checks, and physical opt-in tests |
| [Security policy](../SECURITY.md) | Private vulnerability reporting and maintenance scope |
| [Code of Conduct](../CODE_OF_CONDUCT.md) | Community expectations and conduct reporting |

## Product and content decisions

| Document | Owns |
| --- | --- |
| [Project overview](Project-Overview.md) | Implemented state, evidence limits, and the next milestone |
| [Product brief](Product-Brief.md) | Intended experience, claim boundaries, and first-release scope; some features remain future work |
| [Project implementation plan](Project-Implementation-Plan.md) | Durable phased roadmap and acceptance criteria |
| [Decision log](Decision-Log.md) | Accepted choices, their reasons, and open acceptance checks |
| [Content catalog](Content-Catalog.md) | Bundled schema, citations, revisions, and audio identity |
| [Content review](Content-Review.md) | Editorial and factual review of the original scripts |
| [Audio preparation](Audio-Preparation.md) | Current George and rain provenance, measurements, reproducible preparation, and historical auditions |
| [Narration reference](Narration-Reference.md) | Historical Apple voice listening reference and its supersession by George |
| [Audio measurements](Audio-Preparation-Measurements.json) | Machine-readable preparation and audition evidence referenced by the audio guide |

## Keep the docs consistent

[Implementation-Plan.md](Implementation-Plan.md) is the replaceable plan for the current task. It is not the product roadmap. Update durable status and sequencing in the project overview and project implementation plan.

Describe current controls in the user guide, setup in getting started, and commands in development. Link to those pages from evidence logs instead of keeping duplicate setup recipes. When behavior changes, update the canonical contract, user guidance, and any affected README graphic together. Preserve dated evidence as history; do not silently turn unobserved outcomes into passes.

The README illustrations in [assets/](assets/) are original editable SVGs. They are conceptual guides, not app screenshots or guarantees of timing. Each has a title/description, a readable background, and adjacent text equivalents in the README. Keep text, controls, and stated limits synchronized; inspect both wide and narrow rendering after editing.
