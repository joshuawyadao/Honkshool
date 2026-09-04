# Honkshool product brief

## Purpose

Honkshool is an iPhone app for calm, uninterrupted factual narration during naps and bedtime. Helping the listener relax and fall asleep is the primary purpose; exposure to interesting information is secondary.

The product replaces a fragile routine of browsing YouTube for suitable long-form audio, encountering ads or autoplay, and setting a separate alarm. Its intended flow is:

> Open app → choose content → choose nap duration → review the Nap Plan → start resting.

## Claim boundaries

Honkshool must not claim or imply that a listener:

- learns subconsciously while asleep;
- retains everything that plays;
- receives therapy; or
- is being treated for insomnia or any other medical condition.

The app describes sessions as **played**, not learned, mastered, or retained. Completion means that playback reached the end; it does not make a claim about whether the listener was awake or understood the material.

## Audience and validation goal

The first build is for the project owner’s personal iPhone. It succeeds if Honkshool is naturally chosen instead of browsing YouTube for most of approximately ten real naps, the experience is calm and uninterrupted, and the wake alarm is dependable.

This is a useful project even if it remains a small personal app.

## Core experience

### Learning journeys

Content is organized into finite journeys of approximately five to eight sessions. Completing a journey can reveal several recommended journeys, gradually forming a personal knowledge tree of what was played and which path was followed.

A listener can:

- continue the current journey;
- explore a new journey or choose a random topic;
- return to past journeys and sessions;
- replay a session or restart a journey; and
- revisit a skipped branch or take a different branch without erasing earlier history.

A session advances automatically when it plays to completion. History makes any missed material available again.

### Nap Plans

The listener chooses an overall nap duration or wake time. Honkshool assembles available content to fit that window without increasing narration speed.

A Nap Plan can contain:

- a short settling period;
- one or more factual sessions;
- a lower-density drift period;
- offline ambience or silence; and
- an optional final wake alarm.

Before starting, the plan shows the duration or wake time, current journey and upcoming sessions, any journey boundary crossed, post-narration behavior, ambience selection, and alarm status and time.

At a journey boundary, the default can be to continue into the recommended journey, transition to ambience, or fade to silence. If a nap crosses into another journey, the proposed route is selected and displayed before the nap and is implicitly approved unless the listener changes it.

Once playback starts, the route is fixed. Honkshool must not vibrate, speak a question, regenerate content, or present an attention-demanding branch prompt while the listener may be asleep.

## Initial content

The first subject is automotive mechanics. The first journey is **How a Car Works**, with candidate sessions:

1. Turning Fuel Into Motion
2. Air, Fuel, and Spark
3. Oil and Cooling
4. Gears and Torque
5. Steering, Suspension, and Tires
6. Braking
7. The Car as One System

The first major recommended branch is **Rally Engineering**, including traction, changing surfaces, suspension, weight transfer, all-wheel drive, differentials, turbocharging, durability, and system integration.

A later branch is **Formula 1 Engineering History**, including layouts, aerodynamics, ground effect, engine philosophies, materials, electronics, and hybrid energy recovery.

Content emphasizes understandable mental models and engineering relationships. It avoids anxiety-producing failure warnings and detailed repair procedures that should be followed while fully alert.

## Content reliability and copyright

The first prototype uses a tiny prepared catalog. It does not perform live research, arbitrary internet topic generation, runtime AI generation, or backend content delivery.

The intended future authoring pipeline is:

1. Consult multiple reputable sources.
2. Extract and cross-check factual claims.
3. Write an original, calm script.
4. Retain source citations with the session.
5. Perform a factual-consistency check.
6. Convert the script to narration.
7. Show sources in the app without reading citations aloud.

Public accessibility is not permission to reproduce an article. Scripts must be original works based on cross-checked facts and appropriately retained citations.

## Detail levels

The future product may offer Relaxed Overview, Enthusiast, and Technical detail per journey. These levels should use approximately the same session duration and vary vocabulary, explanation depth, analogy use, and repetition—not narration speed or the structure of the Nap Plan.

The first prototype includes only Enthusiast-level content. Future “Simpler next time” and “Go deeper next time” controls affect the next session and never interrupt or regenerate the session already playing.

## Audio and ambience

The first version uses one carefully selected Apple on-device voice. Calmness comes from the script and pacing: a modestly slower speaking rate, natural punctuation, short sentences, pauses between ideas and paragraphs, careful technical pronunciation, gradual volume reduction in the drift phase, and minimal pitch manipulation.

Ambience is independent of the subject. The first version needs one lawfully distributable offline ambience option and silence. Ambience remains available without a network connection and provides a fallback if other future content is unavailable.

A normal factual session initially targets approximately 12–15 minutes, but this is a hypothesis to test rather than a permanent constant.

## Local history and storage

The first version keeps listening history on the device and has no account or iCloud sync. History retains lightweight information including session and journey identity, date played, playback duration and completion, detail level, position in the journey tree, summary, sources, and available branches.

Partially played content remains resumable. Future downloaded narration may be deleted after successful playback while its history remains; content explicitly kept offline remains until the listener removes it. Because the first version uses on-device speech, it may retain only scripts and metadata rather than generated audio files.

## Alarm behavior

Honkshool targets iOS 26 or newer and intends to use AlarmKit for a genuine system-level nap alarm. The alarm is configured in the Nap Plan, uses familiar native time-selection patterns, remains dependable when the app is backgrounded, and supports appropriate system stop and snooze behavior.

The wake alarm is the only intentional attention-demanding event during the nap. Honkshool manages only alarms it creates and does not edit alarms or Sleep schedules owned by Apple’s Clock or Health apps.

## Technical boundaries

- iPhone-first, with iOS 26 as the minimum target.
- Swift and SwiftUI.
- SwiftData for local persistence.
- AlarmKit for nap alarms.
- AVFoundation and AVSpeechSynthesizer for narration and background audio.
- Appropriate Lock Screen media controls.
- Native frameworks preferred over third-party dependencies.
- No backend, accounts, analytics, cloud sync, subscriptions, ads, or paid API dependencies in the first prototype.
- No TestFlight or App Store work initially.

These choices are intended constraints to validate during planning and feasibility work. Material changes belong in the [decision log](Decision-Log.md).

## First-release boundary

The first useful release is a narrow vertical slice that can:

- choose or continue a local journey;
- select a nap duration or wake time;
- review and approve a fixed Nap Plan;
- play one representative automotive session;
- transition to offline ambience or silence;
- schedule a dependable system alarm;
- advance journey progress after completed playback; and
- show local listening history, including partial playback.

Everything else remains deferred until the [implementation plan](Implementation-Plan.md) and real-nap validation justify expansion.
