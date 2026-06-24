#!/usr/bin/env python3

"""Bridge viewport teleop twists to MoveIt Servo.

Subscribes to an unstamped ``geometry_msgs/Twist`` published by the viewport
teleop panel, applies per-axis exponential moving average (EMA) smoothing, and
republishes the result as a ``geometry_msgs/TwistStamped`` for MoveIt Servo.
When no input arrives within ``input_timeout`` seconds the target is treated as
zero so the robot decelerates to a stop.
"""

import rospy
from geometry_msgs.msg import Twist, TwistStamped


class Ur5eViewportTeleopNode(object):
    def __init__(self):
        self.input_twist_topic = rospy.get_param("~input_twist_topic", "/cmd_vel")
        self.output_twist_topic = rospy.get_param("~output_twist_topic", "/servo_server/delta_twist_cmds")
        self.frame_id = rospy.get_param("~frame_id", "base_link")
        self.publish_rate = rospy.get_param("~publish_rate", 100.0)
        self.input_timeout = rospy.get_param("~input_timeout", 0.2)

        # Exponential moving average smoothing factor (0 < alpha <= 1).
        # Lower values produce smoother motion; higher values respond faster.
        self.smoothing_alpha = rospy.get_param("~smoothing_alpha", 0.1)

        self.latest_twist = Twist()
        self.smoothed_twist = Twist()
        self.last_input_time = rospy.Time.now()

        self.publisher = rospy.Publisher(self.output_twist_topic, TwistStamped, queue_size=1)
        self.twist_subscriber = rospy.Subscriber(self.input_twist_topic, Twist, self._handle_twist, queue_size=1)

    def _handle_twist(self, twist_message):
        self.latest_twist = twist_message
        self.last_input_time = rospy.Time.now()

    def _ema(self, current, target):
        return self.smoothing_alpha * target + (1.0 - self.smoothing_alpha) * current

    def _smooth_toward(self, target):
        self.smoothed_twist.linear.x = self._ema(self.smoothed_twist.linear.x, target.linear.x)
        self.smoothed_twist.linear.y = self._ema(self.smoothed_twist.linear.y, target.linear.y)
        self.smoothed_twist.linear.z = self._ema(self.smoothed_twist.linear.z, target.linear.z)
        self.smoothed_twist.angular.x = self._ema(self.smoothed_twist.angular.x, target.angular.x)
        self.smoothed_twist.angular.y = self._ema(self.smoothed_twist.angular.y, target.angular.y)
        self.smoothed_twist.angular.z = self._ema(self.smoothed_twist.angular.z, target.angular.z)

    def _publish_smoothed_twist(self):
        servo_twist = TwistStamped()
        servo_twist.header.stamp = rospy.Time.now()
        servo_twist.header.frame_id = self.frame_id
        servo_twist.twist = self.smoothed_twist
        self.publisher.publish(servo_twist)

    def run(self):
        rate = rospy.Rate(self.publish_rate)

        while not rospy.is_shutdown():
            stale = (rospy.Time.now() - self.last_input_time).to_sec() > self.input_timeout
            target = Twist() if stale else self.latest_twist

            self._smooth_toward(target)
            self._publish_smoothed_twist()

            rate.sleep()


def main():
    rospy.init_node("ur5e_viewport_teleop_node")
    Ur5eViewportTeleopNode().run()


if __name__ == "__main__":
    main()
