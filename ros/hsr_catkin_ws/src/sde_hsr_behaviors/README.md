# sde_hsr_behaviors

The `sde_hsr_behaviors` directory contains the FlexBE behavior packages for the Toyota HSR (Human Support Robot) platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Open-Source Scope

The example HSR behavior is intentionally minimal: it loops between two `LogState` and `WaitState` pairs.
Looping navigation between waypoints (`MoveBaseState`) and arm motion to SRDF named states (`SrdfStateToMoveit`) are not provided here because the open-source `hsr-project` GitHub repositories do not include a ROS Noetic navigation stack or MoveIt configuration for HSR.

## Usage

Start the FlexBE behavior engine and app:

```shell
roslaunch sde_launch flexbe_app_default.launch
```

## Behaviors

| Behavior | Description |
| --- | --- |
| `Hsr Example Behavior` | Minimal looping demo using `LogState` and `WaitState`. |

## External Resources

- FlexBE Behavior Engine: [https://github.com/FlexBE/flexbe_behavior_engine](https://github.com/FlexBE/flexbe_behavior_engine)
- FlexBE App: [https://github.com/FlexBE/flexbe_app](https://github.com/FlexBE/flexbe_app)
- FlexBE Generic States: [https://github.com/FlexBE/generic_flexbe_states](https://github.com/FlexBE/generic_flexbe_states)
