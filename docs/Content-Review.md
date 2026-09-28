# Prepared content review

## Reviewed scope

The bundled [PreparedCatalog.json](../Honkshool/Resources/PreparedCatalog.json) contains two original Enthusiast sessions in **How a Car Works**: **Turning Fuel Into Motion** (`turning-fuel-into-motion`) and **Air, Fuel, and Spark** (`air-fuel-and-spark`). Both use script revision `1` and content language `en-US`, rendered with British-English George. Later candidate sessions and recommended journeys are not represented as available content. The following historical first-session review is followed by the second-session review below.

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

On 2026-09-17 the complete Mac development audition measured **674.222 seconds (11 minutes 14.222 seconds)**. Every whole paragraph received a completed synthesis callback using the reference Aaron voice at rate `0.45`. Offline processing retained that timing, with 0.25 seconds of leading silence, one second between paragraphs, and 0.5 seconds at the end. The planning estimate at that checkpoint was **675 seconds**, calculated as `ceil(674.222 / 5) * 5`. The text and revision did not change.

That measurement is preserved as historical Apple-voice evidence. On 2026-09-21 the unchanged revision-1 script was rendered with the accepted Kokoro George voice at native model speed `0.86`. The verified output measures **727.625 seconds (12 minutes 7.625 seconds)**, so the current configurable estimate is **730 seconds**, calculated as `ceil(727.625 / 5) * 5`. The bundled PCM asset and its provenance are bound to the same session identity, revision, and exact narration-text hash. Listening review must still check the complete session; objective construction checks do not establish pronunciation or comfort.

[Audio-Preparation.md](Audio-Preparation.md) and its measurement record preserve the script hash, paragraph frame counts, processing evidence, and full-file fingerprint. Current estimates describe the bundled prepared WAVs; the app does not resynthesize them on iPhone. Actual overruns still stop at the fixed wake deadline and retain partial progress.

The full script has been rendered, but not accepted through full-session listening. Pronunciation notes remain authoring guidance, not applied speech substitutions. Technical words, pauses, consonants, sustained comfort, and target-device output still need listening review.

## Relationship to earlier audio

The 97-word narration audition was a short voice-and-processing comparison. The owner accepted **F** as a provisional development reference after listening through MacBook speakers. That acceptance does not cover this full script, iPhone playback, or AirPods output. The existing feasibility spike script is also separate and remains available for its original technical purpose.

The prepared catalog bundles both complete George narrations and their provenance alongside text, source metadata, and the selected CC0 rain resource. Preparation environments, model weights, and historical auditions remain outside Git. Automated device evidence and deferred listening, locked-control, and headphone observations are recorded separately; no new subjective acceptance is implied. See the [decision log](Decision-Log.md) and [durable roadmap](Project-Implementation-Plan.md).

## Air, Fuel, and Spark — reviewed 2026-09-28

The second session has 1,847 whitespace-delimited words in 14 paragraphs. It stands alone while continuing the first session's gentle drawing motif. It follows a conventional injected, spark-ignition petrol engine from air admission and measurement through mixture preparation, ignition, finite flame propagation, and feedback. Opening and closing framing are original; the 12 factual paragraphs each link to a primary source. No source prose or media is reproduced.

| Source ID | Reviewed claim / qualification | Source |
| --- | --- | --- |
| `doe-engine-basics` | Energy, pressure, and the four-stroke outline. | [DOE engine basics](https://www.energy.gov/cmei/vehicles/articles/internal-combustion-engine-basics) |
| `bosch-air-management` | Electronic throttle and pedal request; qualified as one arrangement. | [Bosch air management](https://www.bosch-mobility.com/en/solutions/air-management/) |
| `bosch-air-mass` | Heated sensing element turns airflow's thermal effect into information. | [Bosch air-mass meter](https://www.bosch-mobility.com/en/solutions/sensors/hotfilm-airflow-sensor/) |
| `bosch-intake-sensor` | Pressure and temperature sensing support fuel control; sensor combinations vary. | [Bosch intake sensor](https://www.bosch-mobility.com/en/solutions/sensors/intake-manifold-and-boost-pressure-sensor/) |
| `bosch-port-injector` | Injection before the valve; timing can precede or overlap its opening. | [Bosch port injector](https://www.bosch-mobility.com/en/solutions/valves/fuel-injector-manifold/) |
| `bosch-direct-injector` | Metered, atomized fuel enters the chamber from a fuel rail. | [Bosch high-pressure injection valve](https://www.bosch-mobility.com/en/solutions/valves/high-pressure-injector/) |
| `denso-ignition-coil` | Primary current and changing magnetic field produce secondary voltage. | [DENSO ignition coil](https://www.denso-am.eu/products/ignition/ignition-coil) |
| `denso-spark-plug` | Electrical discharge across the electrode gap initiates combustion. | [DENSO spark plug](https://www.denso-am.eu/products/ignition/spark-plug) |
| `doe-flame-propagation` | Normal flame spread takes milliseconds, rather than occurring simultaneously everywhere. | [DOE Co-Optima transcript](https://www.energy.gov/cmei/fuels/text-version-co-optima-webinar-how-can-co-optimized-fuels-and-spark-ignition-engines) |
| `bosch-crank-sensor` | Position and speed signals support injection and ignition timing. | [Bosch crankshaft sensor](https://www.bosch-mobility.com/en/solutions/sensors/crankshaft-speed-sensor/) |
| `bosch-engine-control` | ECU coordination of air, fuel, and ignition. | [Bosch engine-control summary](https://www.bosch-mobility.com/media/global/solutions/passenger-cars-and-light-commercial-vehicles/powertrain-solutions/gasoline-direct-injection/electronic-control-unit/ps_summary_ps_electric_control_unit_ecu_en_rgb_20201202.pdf) |
| `bosch-oxygen-feedback` | Exhaust oxygen supplies feedback for mixture control. | [Bosch lambda sensor](https://www.bosch.com/stories/the-history-of-the-bosch-lambda-sensor/) |

The read-only source review found no required narration correction. It corrected three source display titles and removed one repeated reassurance sentence before rendering. The commercial-vehicle crank-sensor page is used only for the shared sensing principle, not a claim that every passenger car installs that component. Normal combustion, sensor arrangements, and injection timing remain qualified; there are no universal voltage, pressure, mixture-ratio, ignition-angle, efficiency, or service prescriptions. The text offers no quiz, learning claim, diagnostic task, or repair instruction.

Pronunciation guidance covers petrol, injector, electrodes, crankshaft, lambda, and milliseconds. It is metadata rather than an applied phoneme override. Its verified complete render measures 756.75 seconds, with a configurable 760-second estimate. Measured render evidence lives in [Audio-Preparation.md](Audio-Preparation.md) and the second session's bundled provenance. Text/chunk checks prove the submitted input and assembly order; they do not transcribe the output or establish pronunciation and comfort through the complete session.
