# Prepared content review

## Reviewed scope

The bundled [PreparedCatalog.json](../Honkshool/Resources/PreparedCatalog.json) contains one original Enthusiast session, **Turning Fuel Into Motion**, in **How a Car Works**. Session identity is `turning-fuel-into-motion`, script revision is `1`, and language is `en-US`. This is the first prepared session; the remaining candidate sessions and recommended journeys are not represented as available content.

The script follows a common four-stroke, spark-ignition petrol car engine. It covers the relationship between combustion, the piston and crankshaft, the operating cycle, valves, several cylinders, the transmission, cooling, and lubrication. It deliberately avoids repair instructions, failure warnings, performance rankings, and claims of learning or retention. Natural delivery and breathing room between ideas remain the narration direction.

This source and script-consistency review was completed on 2026-09-16. Full-session Mac audio preparation followed on 2026-09-17; listening acceptance remains unverified.

## Original writing and sources

The narration was written as original connected prose after reviewing the sources below. No source sentences, diagrams, audio, or other media are included. Public accessibility was not treated as permission to reproduce an article. Source entries are retained with stable IDs, publisher names, titles, and URLs. Paragraph `sourceIDs` map narration to those entries; opening and closing scene-setting paragraphs have no source references. Citations and pronunciation guidance remain metadata, outside the spoken text.

| Source ID | Reviewed claim / qualification | Source |
| --- | --- | --- |
| `doe-engine-basics` | Combustion pressure produces piston motion and useful mechanical work; the powertrain carries motion toward wheels. | [Internal Combustion Engine Basics — U.S. Department of Energy](https://www.energy.gov/cmei/vehicles/articles/internal-combustion-engine-basics) |
| `nasa-bore-stroke` | Bore, stroke, and displacement; the four-stroke sequence takes two crankshaft turns. | [Bore and Stroke — NASA Glenn](https://www.grc.nasa.gov/WWW/K-12/BGP/stroke.html) |
| `bosch-injection` | Fuel can be injected directly into the chamber; electronic management coordinates delivery and ignition. | [Gasoline Direct Injection — Bosch Mobility](https://www.bosch-mobility.com/en/solutions/powertrain/gasoline/gasoline-direct-injection/) |
| `bosch-port-injection` | Port injection supplies fuel before the inlet valve. This complements the direct-injection account. | [Fuel Injector (PFI) — Bosch Mobility](https://www.bosch-mobility.com/en/solutions/valves/fuel-injector-manifold/) |
| `nasa-mechanical-operation` | Intake, compression, power, exhaust, and the connecting rod's transfer of force to the crankshaft. | [Engine Mechanical Operation — NASA Glenn](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/engine-mechanical-operation/) |
| `honda-valve-operation` | Cam shape, valve lift, and real valve overlap; not every engine uses Honda's variable mechanism. | [B16A and VTEC — Honda](https://global.honda/en/tech/engine/car/B16A_integra_vtec/) |
| `nasa-engine-parts` | Several pistons share a crankshaft; firing order and a flywheel help organise and smooth the motion. | [Engine Parts — NASA Glenn](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/engine-parts/) |
| `openstax-torque` | Torque is the turning effect of force, affected by its point and direction of application. | [6.3 Rotational Motion — OpenStax](https://openstax.org/books/physics/pages/6-3-rotational-motion) |
| `pgcc-gears` | Ideal gears exchange rotational speed for torque while preserving work. | [25.6: Gears — Prince George's Community College course on Physics LibreTexts](https://phys.libretexts.org/Courses/Prince_Georges_Community_College/General_Physics_I:_Classical_Mechanics/25:_Simple_Machines/25.06:_Gears) |
| `ford-powertrain` | The conventional automatic-transmission example leads through a differential to the driven wheels. | [Powertrain Components & Remanufactured Products — Ford](https://parts.ford.com/content/dam/ford-parts/wcdocs/2017%20-%20PTF200%20-%20Reman%20Engines%20%26%20Transmissions.pdf) |
| `denso-radiators` | Coolant transports heat; the radiator exchanges it with passing air, assisted by a fan when needed. | [Cooling Radiators — DENSO Europe](https://www.denso-am.eu/products/ac-engine-cooling/cooling-radiators) |
| `honda-engine-oil` | Oil lubricates moving surfaces, contributes to cooling, and has temperature-dependent flow properties. | [How to Choose the Right Engine Oil — Honda](https://global.honda/en/motorcycle-aftersales/plusone/202504.html) |

### Consistency checks and limits

- DOE and NASA agree on the central energy-to-motion path and four-stroke sequence. NASA's examples depict the Wright brothers' 1903 aircraft engine. The script uses the shared principles, not that engine's historical ignition contacts, carburettor, automatically opened intake valve, or idealised heat-transfer sequence.
- Bosch's port and direct injection descriptions prevent the simplified claim that all petrol engines draw an already mixed charge through the intake valve. The script intentionally leaves injection timing dependent on the arrangement.
- Honda's valve account qualifies the simplified stroke diagram: real events may overlap. Ignition is described as occurring near the end of compression, without prescribing an exact crank angle.
- The cylinder and crank account describes geometry; the combustion account supplies its energy source. The flywheel is not presented as creating energy, and torque is distinguished from rotational speed.
- The transmission passage is explicitly a conventional automatic example. The ideal gear explanation does not claim lossless real transmissions or describe every gearbox design.
- Cooling refers to the liquid-cooled car engine pictured. Oil and cooling passages describe functions without prescribing servicing actions or universal operating temperatures.
- The source descriptions contain engineering simplifications. No universal efficiency percentage, firing order, injection pressure, valve count, or cam-control design is asserted.

## Duration and narration status

The unchanged revision-1 script has **1,838 words in 13 paragraphs**, counting word tokens with apostrophes kept inside words and hyphenated compounds counted separately. Its initial 765-second editorial estimate assumed 150 words per minute plus paragraph pauses; it was explicitly unmeasured.

On 2026-09-17 the complete Mac development audition measured **674.222 seconds (11 minutes 14.222 seconds)**. Every whole paragraph received a completed synthesis callback using the reference Aaron voice at rate `0.45`. Offline processing retained that timing, with 0.25 seconds of leading silence, one second between paragraphs, and 0.5 seconds at the end. The configurable planning estimate is now **675 seconds**, calculated as `ceil(674.222 / 5) * 5`. The text and revision did not change.

That measurement is preserved as historical Apple-voice evidence. On 2026-09-21 the unchanged revision-1 script was rendered with the accepted Kokoro George voice at native model speed `0.86`. The verified output measures **727.625 seconds (12 minutes 7.625 seconds)**, so the current configurable estimate is **730 seconds**, calculated as `ceil(727.625 / 5) * 5`. The bundled PCM asset and its provenance are bound to the same session identity, revision, and exact narration-text hash. Listening review must still check the complete session; objective construction checks do not establish pronunciation or comfort.

[Audio-Preparation.md](Audio-Preparation.md) and its measurement record preserve the script hash, paragraph frame counts, processing evidence, and full-file fingerprint. The estimate describes this Mac audition; target-iPhone direct-speech timing remains uncalibrated. Actual overruns still stop at the fixed wake deadline and retain partial progress.

The full script has been rendered, but not accepted through full-session listening. Pronunciation notes remain authoring guidance, not applied speech substitutions. Technical words, pauses, consonants, sustained comfort, and target-device output still need listening review.

## Relationship to earlier audio

The 97-word narration audition was a short voice-and-processing comparison. The owner accepted **F** as a provisional development reference after listening through MacBook speakers. That acceptance does not cover this full script, iPhone playback, or AirPods output. The existing feasibility spike script is also separate and remains available for its original technical purpose.

This prepared catalog bundles text and source metadata, alongside a separately prepared CC0 rain candidate. Local processed narration stays outside the repository, and the playback runtime remains unchanged. Rain listening acceptance and target-device narration checks remain open work. See the [decision log](Decision-Log.md) and [durable roadmap](Project-Implementation-Plan.md).
