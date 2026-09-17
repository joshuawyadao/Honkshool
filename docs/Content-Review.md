# Prepared content review

## Reviewed scope

The bundled [PreparedCatalog.json](../Honkshool/Resources/PreparedCatalog.json) contains one original Enthusiast session, **Turning Fuel Into Motion**, in **How a Car Works**. Session identity is `turning-fuel-into-motion`, script revision is `1`, and language is `en-US`. This is the first prepared session; the remaining candidate sessions and recommended journeys are not represented as available content.

The script follows a common four-stroke, spark-ignition petrol car engine. It covers the relationship between combustion, the piston and crankshaft, the operating cycle, valves, several cylinders, the transmission, cooling, and lubrication. It deliberately avoids repair instructions, failure warnings, performance rankings, and claims of learning or retention. Natural delivery and breathing room between ideas remain the narration direction.

This source and script-consistency review was completed on 2026-09-16. Full-session listening remains unverified.

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

The current script has **1,838 words in 13 paragraphs**, counting word tokens with apostrophes kept inside words and hyphenated compounds counted as separate words. Its planning estimate is **765 seconds (12 minutes 45 seconds)**:

`ceil((1838 / 150 * 60 + 13 * 2) / 5) * 5`

This assumes 150 words per minute, plus two seconds at each of the 12 paragraph boundaries and after the final paragraph, rounded up to five seconds. It is an **unmeasured, configurable planning estimate**, not a guarantee of the rendered duration. It neither fixes a permanent session length nor implies that this script will reproduce audition F's pace at a particular speech-rate setting. Nap deadlines remain fixed if actual narration overruns this estimate.

The session has not yet been rendered or auditioned in full. Its pronunciation notes are authoring guidance; this branch does not apply them through a speech engine. Later preparation must measure the complete narration and check technical words, pauses, consonants, and transitions before calibration of the estimate.

## Relationship to earlier audio

The 97-word narration audition was a short voice-and-processing comparison. The owner accepted **F** as a provisional development reference after listening through MacBook speakers. That acceptance does not cover this full script, iPhone playback, or AirPods output. The existing feasibility spike script is also separate and remains available for its original technical purpose.

This prepared catalog bundles text and source metadata only. It does not bundle F's processed audio, implement its filtering, select a final rain recording, or change the playback runtime. A lawful, consistent gentle-rain asset and target-device listening checks remain open work. See the [decision log](Decision-Log.md) and [durable roadmap](Project-Implementation-Plan.md).
