# API

## attach_to_world(root: Node3D, shader_forge: Node = null) -> bool
Attaches the climate module to a world root and optionally links to EXO Shader Forge.

## set_weather(name: String) -> void
Supported values: `clear`, `drizzle`, `rain`, `mist`, `storm`, `night`.

## set_wind_strength(value: float) -> void
Range 0.0..1.0.

## set_rain_intensity(value: float) -> void
Range 0.0..1.0.

## set_fog_intensity(value: float) -> void
Range 0.0..1.0.

## set_night_lighting(enabled: bool) -> void
Enables or disables lantern lights.
