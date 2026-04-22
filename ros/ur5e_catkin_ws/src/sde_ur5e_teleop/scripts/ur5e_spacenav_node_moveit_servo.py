#!/usr/bin/env python3

import math
import threading

import rospy
from geometry_msgs.msg import Twist, TwistStamped
from sensor_msgs.msg import Joy


class Ur5eSpacenavNodeMoveitServo(object):
    def __init__(self):
        self.input_twist_topic = rospy.get_param("~input_twist_topic", "/spacenav/twist")
        self.output_twist_topic = rospy.get_param("~output_twist_topic", "/servo_server/delta_twist_cmds")
        self.joy_topic = rospy.get_param("~joy_topic", "/spacenav/joy")
        self.frame_id = rospy.get_param("~frame_id", "flange")
        self.require_enable_button = rospy.get_param("~require_enable_button", True)
        self.enable_button_index = rospy.get_param("~enable_button_index", 0)
        self.publish_zero_when_disabled = rospy.get_param("~publish_zero_when_disabled", True)

        self.linear_x_scale = rospy.get_param("~linear_x_scale", 1.0)
        self.linear_y_scale = rospy.get_param("~linear_y_scale", 1.0)
        self.linear_z_scale = rospy.get_param("~linear_z_scale", 1.0)
        self.angular_x_scale = rospy.get_param("~angular_x_scale", 1.0)
        self.angular_y_scale = rospy.get_param("~angular_y_scale", 1.0)
        self.angular_z_scale = rospy.get_param("~angular_z_scale", 1.0)
        self.publish_rate = rospy.get_param("~publish_rate", 100.0)
        self.input_timeout = rospy.get_param("~input_timeout", 0.1)
        self.linear_deadband = rospy.get_param("~linear_deadband", 0.10)
        self.angular_deadband = rospy.get_param("~angular_deadband", 0.10)
        self.linear_smoothing_time_constant = rospy.get_param("~linear_smoothing_time_constant", 0.08)
        self.angular_smoothing_time_constant = rospy.get_param("~angular_smoothing_time_constant", 0.08)
        self.max_linear_acceleration = rospy.get_param("~max_linear_acceleration", 4.0)
        self.max_angular_acceleration = rospy.get_param("~max_angular_acceleration", 6.0)

        self.enabled = not self.require_enable_button
        self._state_lock = threading.Lock()
        self._target_twist = Twist()
        self._current_twist = Twist()
        self._last_input_time = rospy.Time(0)
        self._last_publish_time = rospy.Time.now()
        self.publisher = rospy.Publisher(self.output_twist_topic, TwistStamped, queue_size=1)
        self.twist_subscriber = rospy.Subscriber(self.input_twist_topic, Twist, self._handle_twist, queue_size=1)
        self.joy_subscriber = None
        self.publish_timer = rospy.Timer(rospy.Duration.from_sec(1.0 / max(self.publish_rate, 1.0)), self._publish_timer_callback)

        if self.require_enable_button:
            self.joy_subscriber = rospy.Subscriber(self.joy_topic, Joy, self._handle_joy, queue_size=1)

    def _handle_joy(self, joy_message):
        button_pressed = False
        if 0 <= self.enable_button_index < len(joy_message.buttons):
            button_pressed = bool(joy_message.buttons[self.enable_button_index])

        was_enabled = self.enabled
        self.enabled = button_pressed

        if was_enabled and not self.enabled:
            with self._state_lock:
                self._reset_twists()
            if self.publish_zero_when_disabled:
                self._publish_zero_twist()

    def _handle_twist(self, twist_message):
        if self.require_enable_button and not self.enabled:
            return

        target_twist = Twist()
        target_twist.linear.x = self._shape_axis(-twist_message.linear.x * self.linear_x_scale, self.linear_deadband)
        target_twist.linear.y = self._shape_axis(-twist_message.linear.y * self.linear_y_scale, self.linear_deadband)
        target_twist.linear.z = self._shape_axis(twist_message.linear.z * self.linear_z_scale, self.linear_deadband)
        target_twist.angular.x = self._shape_axis(-twist_message.angular.x * self.angular_x_scale, self.angular_deadband)
        target_twist.angular.y = self._shape_axis(-twist_message.angular.y * self.angular_y_scale, self.angular_deadband)
        target_twist.angular.z = self._shape_axis(twist_message.angular.z * self.angular_z_scale, self.angular_deadband)

        with self._state_lock:
            self._target_twist = target_twist
            self._last_input_time = rospy.Time.now()

    def _publish_timer_callback(self, _event):
        now = rospy.Time.now()

        with self._state_lock:
            dt = max((now - self._last_publish_time).to_sec(), 1e-3)
            self._last_publish_time = now

            if self.require_enable_button and not self.enabled:
                return

            target_twist = self._target_twist
            if self.input_timeout > 0.0 and (now - self._last_input_time).to_sec() > self.input_timeout:
                target_twist = Twist()

            self._current_twist.linear.x = self._step_axis(
                self._current_twist.linear.x,
                target_twist.linear.x,
                dt,
                self.linear_smoothing_time_constant,
                self.max_linear_acceleration,
            )
            self._current_twist.linear.y = self._step_axis(
                self._current_twist.linear.y,
                target_twist.linear.y,
                dt,
                self.linear_smoothing_time_constant,
                self.max_linear_acceleration,
            )
            self._current_twist.linear.z = self._step_axis(
                self._current_twist.linear.z,
                target_twist.linear.z,
                dt,
                self.linear_smoothing_time_constant,
                self.max_linear_acceleration,
            )
            self._current_twist.angular.x = self._step_axis(
                self._current_twist.angular.x,
                target_twist.angular.x,
                dt,
                self.angular_smoothing_time_constant,
                self.max_angular_acceleration,
            )
            self._current_twist.angular.y = self._step_axis(
                self._current_twist.angular.y,
                target_twist.angular.y,
                dt,
                self.angular_smoothing_time_constant,
                self.max_angular_acceleration,
            )
            self._current_twist.angular.z = self._step_axis(
                self._current_twist.angular.z,
                target_twist.angular.z,
                dt,
                self.angular_smoothing_time_constant,
                self.max_angular_acceleration,
            )

            current_twist = Twist()
            current_twist.linear.x = self._current_twist.linear.x
            current_twist.linear.y = self._current_twist.linear.y
            current_twist.linear.z = self._current_twist.linear.z
            current_twist.angular.x = self._current_twist.angular.x
            current_twist.angular.y = self._current_twist.angular.y
            current_twist.angular.z = self._current_twist.angular.z

        self._publish_twist(current_twist, now)

    def _publish_twist(self, twist_message, stamp=None):
        servo_twist = TwistStamped()
        servo_twist.header.stamp = stamp if stamp is not None else rospy.Time.now()
        servo_twist.header.frame_id = self.frame_id
        servo_twist.twist = twist_message
        self.publisher.publish(servo_twist)

    def _publish_zero_twist(self):
        self._publish_twist(Twist())

    def _reset_twists(self):
        self._target_twist = Twist()
        self._current_twist = Twist()
        self._last_input_time = rospy.Time(0)
        self._last_publish_time = rospy.Time.now()

    @staticmethod
    def _shape_axis(value, deadband):
        magnitude = abs(value)
        if magnitude <= deadband:
            return 0.0

        if deadband >= 1.0:
            return 0.0

        scaled_magnitude = (magnitude - deadband) / (1.0 - deadband)
        return math.copysign(scaled_magnitude, value)

    @staticmethod
    def _step_axis(current_value, target_value, dt, smoothing_time_constant, max_acceleration):
        if smoothing_time_constant > 0.0:
            alpha = 1.0 - math.exp(-dt / smoothing_time_constant)
            target_value = current_value + alpha * (target_value - current_value)

        delta = target_value - current_value
        if max_acceleration > 0.0:
            max_delta = max_acceleration * dt
            delta = max(-max_delta, min(max_delta, delta))

        return current_value + delta


def main():
    rospy.init_node("ur5e_spacenav_node_moveit_servo")
    Ur5eSpacenavNodeMoveitServo()
    rospy.spin()


if __name__ == "__main__":
    main()
