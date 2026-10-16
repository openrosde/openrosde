# openrosde_user_behaviors

The `openrosde_user_behaviors` directory contains the user-overlay FlexBE behavior packages.
Behaviors here are platform-agnostic: they run on top of any `OPENROSDE_ROBOT_PLATFORM`.

## Usage

Start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

Then load and execute the `User Example Behavior`.

## Behaviors

| Behavior | Description |
| --- | --- |
| `User Example Behavior` | Logs a message and waits, demonstrating the user-overlay FlexBE setup. |

## External Resources

- FlexBE Behavior Engine: [https://github.com/FlexBE/flexbe_behavior_engine](https://github.com/FlexBE/flexbe_behavior_engine)
- FlexBE App: [https://github.com/FlexBE/flexbe_app](https://github.com/FlexBE/flexbe_app)
- FlexBE Generic States: [https://github.com/FlexBE/generic_flexbe_states](https://github.com/FlexBE/generic_flexbe_states)
