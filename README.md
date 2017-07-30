<link href="https://fonts.googleapis.com/css?family=Orbitron" rel="stylesheet">

<p align="center">
<img src="orbit_badge_sml.png"/>
</p>
<h1 align="center" style="font-family: 'Orbitron'">The Orbit Programming Language</h1>

## Compiler Utils

This utility project contains the shared, core components of the Orbit bootstrap system. All other Orbit bootstrap libraries depend on this library.

### Compilation Phase

Each step in the compilation process has an associated `CompilationPhase` object. A **phase** is, essentially, a mapping process that transforms the output of a previous phase into the input for the next phase. As such, they are composable. The `CompilationChain` class provides a convenient way to **chain** two phases together.