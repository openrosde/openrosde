# openrosde_hsr_behaviors

The `openrosde_hsr_behaviors` directory contains the FlexBE behavior packages for the Toyota HSR (Human Support Robot) platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Open-Source Scope

The example HSR behavior implements looping navigation between two waypoints in the WRS 2020 apartment world using `MoveBaseState` and `WaitState`, mirroring the structure of the TurtleBot3 and Fetch examples.
The Toyota `tmc_wrs_binary` image ships a working ROS Noetic MoveIt configuration, so behaviors using `SrdfStateToMoveit` (against the `arm`/`whole_body` MoveIt groups) can be added in the FlexBE App on top of this example.

## Usage

Start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

## Behaviors

| Behavior | Description |
| --- | --- |
| `HSR Example Behavior` | Looping navigation between two waypoints using `MoveBaseState` and `WaitState`. |

## External Resources

- FlexBE Behavior Engine: [https://github.com/FlexBE/flexbe_behavior_engine](https://github.com/FlexBE/flexbe_behavior_engine)
- FlexBE App: [https://github.com/FlexBE/flexbe_app](https://github.com/FlexBE/flexbe_app)
- FlexBE Generic States: [https://github.com/FlexBE/generic_flexbe_states](https://github.com/FlexBE/generic_flexbe_states)
